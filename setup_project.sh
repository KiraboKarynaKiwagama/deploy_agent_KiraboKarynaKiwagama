#!/bin/bash

#these are variable placeholders (they enable the code to accept whatever value is later received as input)
PROJECT_NAME=""
CLEAN_NAME=""
PROJECT_DIR=""

cleanup_interrupt() {
echo ""
echo ""
echo " INTERRUPTED BY USER!"

#only clean up if we have a project directory
if [ -n "$PROJECT_DIR" ] && [ -d "$PROJECT_DIR" ]; then
	echo "Creating archive of incomplete work..."

	#create archive filename
	ARCHIVE_NAME="attendance_tracker_${CLEAN_NAME}_archive"

	#create the archive
	tar -czf "$ARCHIVE_NAME" "$PROJECT_DIR" 2>/dev/null
	
	if [ $? -eq 0 ]; then
		echo "Archive create: $ARCHIVE_NAME"
	else
		echo "Failed to create archive"
	fi

	#remove the incomplete directory
	echo "Cleaning up incomplete directory..."
	rm -rf "$PROJECT_DIR"
fi

echo "Exiting..."
exit 1

}

#set up the trap to catch CTRL+C
trap cleanup_interrupt SIGINT

#create a menu function for the options that the script will present when run

show_menu() {
        clear #this clears the screen so that the user focuses on the menu
        echo "ATTENDANCE TRACKER PROJECT FACTORY"
        echo "=================================="
        echo "1. Setup Directory Architecture"
        echo "2. Configure Attendance Thresholds"
        echo "3. Run Environment Validation"
        echo "4. Run Complete Setup (All Steps)"
        echo "5. Exit"
        echo "========================================="
        echo -n "Enter your choice [1-5]: " #the number the user chooses decides what code will be run
}

setup_directories() {
        echo " Starting the directory architcture setup..."

        #Asking the user for the name they of their project
        echo -n "Enter directory name: "
        read PROJECT_NAME #the input will be kept in this variable

        #clean the name that the user placed (incase of any spaces)
         CLEAN_NAME=$(echo "$PROJECT_NAME" | tr '' '_')
        PROJECT_DIR="attendance_tracker_$CLEAN_NAME"

        echo "Creating the project structure for : $PROJECT_NAME"

        #need to check if directory already exists to avoid duplicates
        if [ -d "$PROJECT_DIR" ]; then
                echo "Directory already exists! Removing the old version..."
                rm -rf "$PROJECT_DIR" #any directory with the same name has now been deleted with everything it included

        fi

        #creation of new main directory
        mkdir "$PROJECT_DIR"

        #now the creation of the directories within the main directory
        mkdir "$PROJECT_DIR/Helpers"
        mkdir "$PROJECT_DIR/reports"

        #create files with content
        create_python_file
        create_csv_file
         create_config_file
        create_log_file

        echo " Directory structure successfully created "
        echo "Press Enter to continue..."
        read
}

create_python_file() {
        cat > "$PROJECT_DIR/attendance_checker.py" << 'EOF'
import csv
import json
import os
from datetime import datetime

def run_attendance_check():

    # 1. Load Config
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)

    # 2. Archive old reports.log if it exists
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log',
                  f'reports/reports_{timestamp}.log.archive')

    # 3. Process Data
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log',
                                                         'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']
        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")

        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])

            # Simple Math: (Attended / Total) * 100
            attendance_pct = (attended / total_sessions) * 100

            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."

            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()                   
EOF
}

create_csv_file() {
        cat > "$PROJECT_DIR/Helpers/assets.csv" << 'EOF'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
noah@example.com,Noah Harris,6,9
olivia@example.com,Olivia Martin,10,5
ava@example.com,Ava Garcia,8,7
logan@example.com,Logan Lewis,9,6
harper@example.com,Harper Lee,7,8
diana@example.com, Diana Prince, 15,0
EOF
}

create_config_file() {
        cat > "$PROJECT_DIR/Helpers/config.json" << 'EOF'
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
EOF
}

create_log_file() {
        touch "$PROJECT_DIR/reports/reports.log"
}

configure_thresholds() {
    echo "=== CONFIGURE ATTENDANCE THRESHOLDS ==="

    # Check if project directory exists
    if [ ! -d "$PROJECT_DIR" ]; then
        echo "Error: Project directory not found!"
        echo "Please run 'Directory Architecture Setup' first."
        echo "Press Enter to continue..."
        read
        return
    fi

     # Show current values
    echo "Current configuration:"
    cat "$PROJECT_DIR/Helpers/config.json"
    echo ""

    # Ask if user wants to update
    echo -n "Do you want to update the thresholds? (yes/no): "
    read answer

    if [ "$answer" = "yes" ]; then
    # Get new values from the user
    echo -n "Enter Warning threshold (default 75): "
    read warning
    echo -n "Enter Failure threshold (default 50): "
    read failure

    #a precaution incase no input is placed
    warning=${warning:-75}
    failure=${failure:-50}

    # Update using sed, replacing the old threshold with the new one
        sed -i "s/\"warning_threshold\": 75,/\"warning_threshold\": $warning,/" "$PROJECT_DIR/Helpers/config.json"
        sed -i "s/\"failure_threshold\": 50/\"failure_threshold\": $failure/" "$PROJECT_DIR/Helpers/config.json"
# Update using sed
        sed -i "s/\"warning_threshold\": 75,/\"warning_threshold\": $warning,/" "$PROJECT_DIR/Helpers/config.json"
        sed -i "s/\"failure_threshold\": 50/\"failure_threshold\": $failure/" "$PROJECT_DIR/Helpers/config.json"

	echo "Configuration updated!"
	echo "New configuration:"
	cat "$PROJECT_DIR/Helpers/config.json"
    else
	echo "Using default thresholds"
    fi

    echo "Press Enter to continue..."
    read

}

validate_environment() {
	echo "Starting environment validation...."

	#check Python3 installation
	echo "1.Checking Python3 installation..."
	if command -v python3 &> /dev/null; then
		python_version=$(python3 --versison 2>&1)
		 echo "$python_version"
    else
        echo " WARNING: Python3 not found!"
        echo " The attendance_checker.py script requires Python3."
    fi
    
#Check directory structure
    echo ""
    echo "2. Checking directory structure..."

    if [ ! -d "$PROJECT_DIR" ]; then
        echo " Project directory not found!"
        echo " Please run 'Directory Architecture Setup' first."
    else
        

        #Check each required file making sure it exists in the directory that exists 
        errors=0

 	if [ -f "$PROJECT_DIR/attendance_checker.py" ]; then
            echo "    attendance_checker.py - OK"
        else
            echo "    attendance_checker.py - MISSING"
            errors=$((errors + 1))
 	fi

 	if [ -f "$PROJECT_DIR/Helpers/assets.csv" ]; then
            echo "    Helpers/assets.csv - OK"
        else
            echo "    Helpers/assets.csv - MISSING"
            errors=$((errors + 1))
 	fi

	if [ -f "$PROJECT_DIR/Helpers/config.json" ]; then
            echo "    Helpers/config.json - OK"
        else
            echo "    Helpers/config.json - MISSING"
            errors=$((errors + 1))
        fi

 	if [ -f "$PROJECT_DIR/reports/reports.log" ]; then
            echo "    reports/reports.log - OK"
        else
            echo "    reports/reports.log - MISSING"
            errors=$((errors + 1))
        fi

	if [ $errors -eq 0 ]; then
		echo ""
		echo "All checks passed! Environment is ready." 
	else
		echo ""
		echo " Found $errors issues. Please fix them." 
	fi
    fi

echo "Press Enter to continue..."
read
}

complete_setup() { #this function iso to help the user run the other functions at once
	echo " ===COMPLETE SETUP=== "
	echo "This will run all setup steps in sequence."
	echo "Please press enter to begin the process..."
	read

setup_directories
configure_thresholds
validate_environment

	echo ""
	echo "The setup has been completed"
	echo "The project is located in $PROJECT_DIR"
	echo "To run the attendance tracker: "
	echo "  cd $PROJECT_DIR"
    	echo "  python3 attendance_checker.py"
    	echo "Press Enter to return to menu..."
    	read
}

main () {
while true; do
	show_menu
	read choice

	case $choice in 
		1) 
			setup_directories 
			;;
		2)
			configure_thresholds
			;;
		3)
			validate_environment
			;;
		4)
			complete_setup
			;;
		5)
			echo "BYE BYE, see you later <3!"
			exit 0
			;;
		*)
			echo "Invalid choice. Please enter 1-5."
			echo "Press Enter o continue..."
			read
			;;
	esac
done
}

#start the program
main

