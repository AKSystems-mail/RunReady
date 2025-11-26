import { GoogleGenAI } from "@google/genai";
import { RoutePreferences, RouteData, WeatherInfo } from '../types';

const ai = new GoogleGenAI({ apiKey: import.meta.env.VITE_GEMINI_API_KEY });

const SYSTEM_INSTRUCTION = `
You are an expert running coach and route planner. Your goal is to find specific, real-world running routes for users based on their location and distance preferences using Google Maps data. 
You also provide safety and weather advice.
When generating a route:
1. Use the googleMaps tool to find actual landmarks, streets, and paths.
2. Use the googleSearch tool to check the current weather, sunrise, and sunset times for the location.
3. If the user wants a "Loop", the start and end point should be the same or very close.
4. If "Finish Line", the end point should be approximately the requested distance away.
5. Provide a text description of the turn-by-turn directions.
6. Assess if the weather is comfortable for running (Ideal: 5°C - 20°C / 40°F - 68°F). Warn if outside this range or if raining.
7. Crucial: You must identify specific street addresses or clear landmarks for the Start, End, and key intermediate Waypoints so a map can be plotted.
`;

export const generateRunRoute = async (
  prefs: RoutePreferences,
  userLatLong?: { lat: number, lng: number }
): Promise<RouteData> => {

  const locationString = prefs.customLocation
    ? prefs.customLocation
    : userLatLong
      ? `${userLatLong.lat}, ${userLatLong.lng}`
      : "my current location";

  let modeInstruction = "";
  if (prefs.mode === 'local') {
    modeInstruction = `
      MODE: LOCAL. 
      - Generate a compact route very close to the start location. 
      - Focus on circling safe neighborhood blocks, local parks, or a nearby track.
      - Keep it simple and safe. Avoid major highways.
      - The route should feel like a "home base" run.
    `;
  } else {
    modeInstruction = `
      MODE: EXPLORER.
      - Generate a scenic route that explores the area.
      - Look for interesting landmarks, trails, or popular running paths nearby.
      - Ideally, the route should offer some variety in scenery.
    `;
  }

  const prompt = `
    Plan a ${prefs.distance} ${prefs.unit} running route in ${locationString}.
    Route Type: ${prefs.routeType === 'loop' ? 'Loop (start and end at same spot)' : 'Point-to-Point (Finish Line away from start)'}.
    ${modeInstruction}
    
    Tasks:
    1. Find a specific route using Google Maps.
    2. Check the current weather for this location right now. Include temp, conditions, and sunrise/sunset.
    3. Output the response in a structured text format (Markdown).
    
    Format the output exactly like this in Markdown:
    # Route Title (e.g., "Scenic Park Loop")
    
    ## Description
    [A very concise paragraph describing the route path, streets, and terrain. Maximum 3-5 sentences.]

    ## MapData
    Start: [Specific Start Address or Lat/Long]
    End: [Specific End Address or Lat/Long]
    Waypoints: [Waypoint 1 Address] | [Waypoint 2 Address] | [Waypoint 3 Address]

    ## Directions
    - [Step 1: Start at...]
    - [Step 2: Turn left on...]
    - [Step 3...]

    ## Weather
    Temp: [Value]
    Condition: [Value]
    Precipitation: [Value]
    Sunrise: [Time]
    Sunset: [Time]
    Comfortable: [Yes/No]
    Warnings: [List any heat/cold/rain warnings]
  `;

  let toolConfig = undefined;
  if (!prefs.customLocation && userLatLong) {
    toolConfig = {
      retrievalConfig: {
        latLng: {
          latitude: userLatLong.lat,
          longitude: userLatLong.lng
        }
      }
    };
  }

  try {
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt,
      config: {
        systemInstruction: SYSTEM_INSTRUCTION,
        tools: [
          { googleMaps: {} },
          { googleSearch: {} }
        ],
        toolConfig: toolConfig
      },
    });

    const text = response.text || "";
    const chunks = response.candidates?.[0]?.groundingMetadata?.groundingChunks || [];

    // Parse the markdown text for sections
    const titleMatch = text.match(/^# (.*$)/m);
    const descriptionMatch = text.match(/## Description\s+([\s\S]*?)(?=##|$)/);
    const directionsMatch = text.match(/## Directions\s+([\s\S]*?)(?=##|$)/);
    const weatherMatch = text.match(/## Weather\s+([\s\S]*?)(?=##|$)/);
    const mapDataMatch = text.match(/## MapData\s+([\s\S]*?)(?=##|$)/);

    // Parse Directions list
    const directionsRaw = directionsMatch ? directionsMatch[1].trim() : "";
    const directions = directionsRaw
      .split('\n')
      .map(line => line.replace(/^[-*]\s*/, '').trim())
      .filter(line => line.length > 0);

    // Parse Map Data for Iframe Construction
    let mapData = undefined;
    if (mapDataMatch) {
      const mapText = mapDataMatch[1];
      const start = mapText.match(/Start: (.*)/i)?.[1]?.trim();
      const end = mapText.match(/End: (.*)/i)?.[1]?.trim();
      const waypointsStr = mapText.match(/Waypoints: (.*)/i)?.[1]?.trim();

      if (start && end) {
        mapData = {
          start,
          end,
          waypoints: waypointsStr ? waypointsStr.split('|').map(s => s.trim()).filter(s => s.length > 0) : []
        };
      }
    }

    // Parse Weather details
    const weatherText = weatherMatch ? weatherMatch[1] : "";
    const temp = weatherText.match(/Temp: (.*)/i)?.[1]?.trim() || "Unknown";
    const cond = weatherText.match(/Condition: (.*)/i)?.[1]?.trim() || "Unknown";
    const precip = weatherText.match(/Precipitation: (.*)/i)?.[1]?.trim() || "None";
    const sunrise = weatherText.match(/Sunrise: (.*)/i)?.[1]?.trim() || "--:--";
    const sunset = weatherText.match(/Sunset: (.*)/i)?.[1]?.trim() || "--:--";
    const isComfortable = weatherText.match(/Comfortable: (Yes|No)/i)?.[1]?.toLowerCase() === 'yes';
    const warningLine = weatherText.match(/Warnings: (.*)/i)?.[1]?.trim() || "";
    const warnings = warningLine && warningLine.toLowerCase() !== 'none' ? [warningLine] : [];

    // Extract grounding waypoints (keeping for fallback or references)
    const waypoints = chunks
      .filter(c => c.maps && c.maps.title && c.maps.uri)
      .map(c => ({
        title: c.maps!.title!,
        uri: c.maps!.uri!
      }));

    return {
      id: crypto.randomUUID(),
      title: titleMatch ? titleMatch[1].trim() : "Custom Run Route",
      description: descriptionMatch ? descriptionMatch[1].trim() : "No description provided.",
      directions: directions,
      mapData: mapData,
      waypoints: waypoints,
      weather: {
        temperature: temp,
        condition: cond,
        precipitationChance: precip,
        sunrise,
        sunset,
        isComfortable,
        warnings
      },
      createdAt: Date.now(),
      preferences: prefs
    };

  } catch (error) {
    console.error("Gemini API Error:", error);
    throw new Error("Failed to generate route. Please try again.");
  }
};