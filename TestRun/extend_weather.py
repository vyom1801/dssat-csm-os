import os

def is_leap_year(year):
    return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)

input_file = 'UFGA1201.WTH'
output_file = 'UFGA1201_extended.WTH' # Write to a new file first to be safe

header_lines = []
data_lines = []

with open(input_file, 'r') as f:
    lines = f.readlines()
    
# Header is the first 4 lines
header_lines = lines[:4]

# Data for the first year (2012) is from line 5 to 370 (0-indexed: 4 to 369)
# Line 370 is 12366
data_lines = lines[4:370]

print(f"Read {len(header_lines)} header lines.")
print(f"Read {len(data_lines)} data lines for year 2012.")

output_lines = []
output_lines.extend(header_lines)

start_year = 2012
num_years = 10

for i in range(num_years):
    current_year = start_year + i
    year_short = current_year % 100
    leap = is_leap_year(current_year)
    days = 366 if leap else 365
    
    print(f"Generating data for year {current_year} ({year_short}), Leap: {leap}, Days: {days}")
    
    for doy in range(1, days + 1):
        # Find the corresponding template line
        # If we have 366 lines in template, we can just use the first 365 for non-leap years
        # and all 366 for leap years.
        # Wait, if the template is from a leap year (2012), it has 366 days.
        # For non-leap years, we just drop the 366th day.
        
        template_line = data_lines[doy - 1]
        
        # The template line has format: "12001   8.2   2.7  -3.9   0.0\n"
        # We need to replace the first 5 characters with the new date
        date_str = f"{year_short:02d}{doy:03d}"
        new_line = date_str + template_line[5:]
        output_lines.append(new_line)

with open(output_file, 'w') as f:
    f.writelines(output_lines)

print(f"Extended weather file written to {output_file}")
