#!/bin/bash

# Input Timetable File
INPUT_FILE="timetable.txt"

# Output CSV File
OUTPUT_FILE="courses_calendar.csv"

# Write the Google Calendar CSV Headers
echo "Subject,Start Date,Start Time,End Date,End Time,Description,Location" > "$OUTPUT_FILE"

# Temporary variables to hold course data
course_name=""
course_code=""
section=""
delivery=""
professor=""
location=""
day_of_class=""
start_time=""
end_time=""
start_date=""
end_date=""
withdrawal_date=""

# Function to clean up text by removing extra spaces
clean_text() {
    echo "$1" | sed 's/[[:space:]]*$//g' | sed 's/^[[:space:]]*//g'
}

# Function to format date (converts DD-Mon-YYYY to YYYY-MM-DD)
format_date() {
    date -d "$1" "+%Y-%m-%d"
}

# Function to process and write to CSV
write_to_csv() {
    # Add entry only if all required fields are set
    if [[ -n "$course_name" && -n "$start_date" && -n "$day_of_class" && -n "$start_time" && -n "$end_date" && -n "$end_time" && -n "$location" ]]; then
        # Clean up location field
        clean_location=$(clean_text "$location")
        
        # Format withdrawal date
        formatted_withdrawal=$(format_date "$withdrawal_date")
        
        # Construct description field with clean spacing
        description="Course Code:$course_code|Section:$section|Delivery:$delivery|Professor:$professor|Academic Penalty Withdrawal Date:$formatted_withdrawal"
        
        # Format data for CSV
        current_date=$(date -I -d "$start_date")
        end_date_epoch=$(date -d "$end_date" +%s)

        # Loop to add weekly events until the end date
        while [[ $(date -d "$current_date" +%s) -le $end_date_epoch ]]; do
            echo "$course_name,$current_date,$start_time,$current_date,$end_time,$description,$clean_location" >> "$OUTPUT_FILE"
            current_date=$(date -I -d "$current_date + 7 days")  # Increment by one week
        done
    fi
}

# Read the timetable file line by line
while IFS= read -r line || [[ -n "$line" ]]; do
    # Trim whitespace
    line=$(clean_text "$line")

    # Check and parse each line
    if [[ "$line" == "Course Name:"* ]]; then
        write_to_csv  # Write the previous course entry before processing a new one
        course_name="${line#Course Name: }"
        course_code=""  # Reset fields for next entry
        section=""
        delivery=""
        professor=""
        location=""
        day_of_class=""
        start_time=""
        end_time=""
        start_date=""
        end_date=""
        withdrawal_date=""
    elif [[ "$line" == "Course Code:"* ]]; then
        course_code=$(clean_text "${line#Course Code: }")
    elif [[ "$line" == "Section:"* ]]; then
        section=$(clean_text "${line#Section: }")
    elif [[ "$line" == "Delivery:"* ]]; then
        delivery=$(clean_text "${line#Delivery: }")
    elif [[ "$line" == "Professor:"* ]]; then
        professor=$(clean_text "${line#Professor: }")
    elif [[ "$line" == "Room Number/ Location:"* ]]; then
        location=$(clean_text "${line#Room Number/ Location: }")
    elif [[ "$line" == "Day of Class:"* ]]; then
        day_of_class=$(clean_text "${line#Day of Class: }")
    elif [[ "$line" == "Time:"* ]]; then
        time_range="${line#Time: }"
        start_time=$(clean_text "${time_range% until*}")
        end_time=$(clean_text "${time_range#*until }")
    elif [[ "$line" == "Start Date:"* ]]; then
        start_date=$(clean_text "${line#Start Date: }")
    elif [[ "$line" == "End Date:"* ]]; then
        end_date=$(clean_text "${line#End Date: }")
    elif [[ "$line" == "Academic Penalty Withdrawal Date:"* ]]; then
        withdrawal_date=$(clean_text "${line#Academic Penalty Withdrawal Date: }")
    elif [[ -z "$line" ]]; then
        # Write previous course to CSV if we encounter an empty line (end of course block)
        write_to_csv
    fi
done < "$INPUT_FILE"

# Write the last course after finishing the loop
write_to_csv

echo "CSV file \"$OUTPUT_FILE\" has been generated and is ready for import into Google Calendar."