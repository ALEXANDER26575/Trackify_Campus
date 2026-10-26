import asyncio 
from playwright.async_api import async_playwright 
from pydantic import BaseModel, Field, ValidationError 

class EventModel(BaseModel): 
    title: str = Field(..., min_length=3) 
    venue: str 
    event_type: str = Field(..., alias="type") 
    timestamp: str 

async def scrape_portal_schedule(url: str): 
    async with async_playwright() as p: 
        browser = await p.chromium.launch(headless=True)  
        page = await browser.new_page() 
        await page.goto(url) 
        # Scrape dynamically rendered table elements 
        rows = await page.query_selector_all("table#schedule-table tr") 
        scraped_data = [] 
        for row in rows[1:]: # Skip header row 
            cols = await row.query_selector_all("td") 
            if len(cols) >= 4: 
                raw_event = { 
                    "title": await cols[0].inner_text(), 
                    "venue": await cols[1].inner_text(), 
                    "type": await cols[2].inner_text(), 
                    "timestamp": await cols[3].inner_text(), 
                } 
                # Runtime validation using Pydantic 
                try: 
                    validated_event = EventModel(**raw_event) 
                    scraped_data.append(validated_event.dict()) 
                except ValidationError as e: 
                    print(f"Validation Error encountered: {e}") 
        await browser.close() 
        return scraped_data 

if name == "__main__": 
    result = asyncio.run(scrape_portal_schedule("https://portal.university.edu/schedules")) 
    print(f"Successfully scraped and validated {len(result)} records.")