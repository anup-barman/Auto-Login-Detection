# Makefile for Automated Attendance System

.PHONY: all install run extract alert stop clean export

all: install extract

install:
	@echo "Installing dependencies..."
	bash install.sh

run:
	@echo "Starting the backend API..."
	cd backend && python3 ../venv/bin/gunicorn -b 0.0.0.0:5000 app:app --daemon || python3 app.py &
	@echo "Backend started on port 5000."
	@echo "Now open 'frontend/index.html' in your web browser!"

extract:
	@echo "Extracting logs..."
	bash scripts/extract_logs.sh

alert:
	@echo "Running absentee check..."
	bash scripts/alert_absentees.sh

export:
	@echo "Exporting database to CSV..."
	bash scripts/export_csv.sh

stop:
	@echo "Stopping backend..."
	pkill -f "app.py" || true

clean:
	@echo "Cleaning database..."
	rm -rf data/*.db
