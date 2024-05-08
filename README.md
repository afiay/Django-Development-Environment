# Django Project Automated Setup

This README details the process of using a PowerShell script to automate the setup of a Django project, including the creation of a virtual environment, installation of dependencies, and starting the project with a custom User model.

## Overview

The PowerShell script automates the following tasks:
- Creating a virtual environment for the Django project.
- Installing all necessary Python packages.
- Initializing a Django project and app.
- Setting up a basic model, view, and template structure.
- Populating the database with fake data using the Faker library.

## Prerequisites

Before running the script, ensure you have the following installed on your system:
- Python 3.x
- pip (Python package installer)
- PowerShell (for Windows users)

## Usage

### Step 1: Download the Script

Download the PowerShell script provided in the repository to your local machine.

### Step 2: Run the Script

Open PowerShell as an administrator and navigate to the directory where you saved the script. Execute the script by running:

```powershell
.\setup_project.ps1
```


