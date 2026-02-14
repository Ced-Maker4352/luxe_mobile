import sys
import json
import requests
from urllib.parse import quote_plus

import re

def search_schools_by_zip(zip_code):
    """
    Fetches real public schools from the NCES (National Center for Education Statistics) directory.
    """
    url = f"https://nces.ed.gov/ccd/schoolsearch/school_list.asp?Search=1&Zip={zip_code}"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code != 200:
            return []
            
        # Use regex to find school links and names
        # Pattern looks for school_detail.asp? links
        matches = re.findall(r'href="school_detail.asp\?[^>]+>([^<]+)</a>', response.text, re.IGNORECASE)
        
        schools = []
        for match in matches:
            name = match.strip().title()
            # Basic deduplication and filtering
            if name and name not in [s['name'] for s in schools]:
                schools.append({
                    "name": name,
                    "city": "Unknown", # Need extra parsing for city/state if needed
                    "state": "",
                    "zip": zip_code
                })
        
        # If no public schools found, try private school search
        if not schools:
            priv_url = f"https://nces.ed.gov/surveys/pss/privateschoolsearch/school_list.asp?Search=1&Zip={zip_code}"
            response = requests.get(priv_url, headers=headers, timeout=10)
            matches = re.findall(r'href="school_detail.asp\?[^>]+>([^<]+)</a>', response.text, re.IGNORECASE)
            for match in matches:
                name = match.strip().title()
                if name and name not in [s['name'] for s in schools]:
                    schools.append({
                        "name": name,
                        "city": "Unknown",
                        "state": "",
                        "zip": zip_code
                    })

        # Try college search (College Navigator)
        college_url = f"https://nces.ed.gov/collegenavigator/?zp={zip_code}"
        response = requests.get(college_url, headers=headers, timeout=10)
        # College names are in <strong> tags within <a> links
        college_matches = re.findall(r'<a href="[^"]+"><strong>([^<]+)</strong></a>', response.text, re.IGNORECASE)
        for match in college_matches:
            name = match.strip().title()
            if name and name not in [s['name'] for s in schools]:
                schools.append({
                    "name": name,
                    "city": "Unknown",
                    "state": "",
                    "zip": zip_code
                })

        return schools[:12] # Return up to 12 results
    except Exception as e:
        return []

def discover_school_identity(school_name):
    """
    Search for official logo and colors for a school using public heuristics and Clearbit.
    """
    try:
        # Heuristic colors based on common themes
        name_lower = school_name.lower()
        
        # Default colors
        primary_color = "#000000"
        secondary_color = "#FFD700" 
        
        # Heuristics for common colors
        if any(x in name_lower for x in ["valley", "university", "state"]): primary_color = "#800000" # Maroon
        if any(x in name_lower for x in ["lake", "ocean", "blue", "sea"]): primary_color = "#000080" # Navy
        if any(x in name_lower for x in ["forest", "oak", "green"]): primary_color = "#006400" # Green
        if any(x in name_lower for x in ["tech", "central", "high"]): primary_color = "#000000" # Black
        
        # Construct a likely domain for the logo if it's a major university
        domain = school_name.replace(" ", "").lower() + ".edu"
        if "highschool" in name_lower or "elementary" in name_lower:
            # For K-12, logos are harder, we'll use a generic placeholder or a search-based one if possible
            logo_url = f"https://ui-avatars.com/api/?name={quote_plus(school_name)}&background=random"
        else:
            logo_url = f"https://logo.clearbit.com/{domain}"
            
        return {
            "name": school_name,
            "colors": [primary_color, secondary_color],
            "logo_url": logo_url
        }
    except Exception as e:
        return {"name": school_name, "colors": ["#000000", "#FFD700"], "logo_url": ""}

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Missing zip code"}))
        sys.exit(1)
        
    command = sys.argv[1]
    
    if command == "list":
        zip_code = sys.argv[2]
        schools = search_schools_by_zip(zip_code)
        print(json.dumps(schools))
    elif command == "identity":
        school_name = sys.argv[2]
        identity = discover_school_identity(school_name)
        print(json.dumps(identity))
    else:
        print(json.dumps({"error": "Unknown command"}))
