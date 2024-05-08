# Get user input for environment, project, and app names
$envName = Read-Host "Enter the name of the virtual environment"
$projectName = Read-Host "Enter the name of your Django project"
$appName = Read-Host "Enter the name of your Django app"


# Create a virtual environment
python -m venv $envName

# Activate the virtual environment
. .\$envName\Scripts\Activate.ps1

# Navigate to the project root directory (assuming it's the current directory)
cd $PWD

# Create a requirements.txt file with latest versions of Django and Pillow, along with other useful libraries
@"
Django
Pillow
djangorestframework
gunicorn
faker
"@ | Out-File requirements.txt

# Install requirements from the requirements.txt file
pip install -r requirements.txt

# Start a new Django project
django-admin startproject $projectName .

# Create a new Django app
python manage.py startapp $appName

# Assume current directory is the project root where manage.py is located

# Navigate into the app directory
cd "$appName"

# Create a templates directory and a subdirectory named after the app
New-Item -ItemType Directory -Path "templates\$appName" -Force

# Add content to views.py
Set-Content -Path "views.py" -Value @"
from django.shortcuts import render
from .models import User

def index(request):
    return render(request, '$appName/base.html')

def home_view(request):
    users = User.objects.all()
    return render(request, '$appName/home.html', {'users': users})

"@

# add content to models.py
Set-Content -Path "models.py" -Value @"
from django.db import models
from django.contrib.auth.models import User

# Create your models here.
class User(models.Model):
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)

    def __str__(self):
        return f"{self.first_name} {self.last_name}"


"@

# Create urls.py and add content
Set-Content -Path "urls.py" -Value @"
from django.urls import path

from . import views

urlpatterns = [
    path('', views.home_view, name='home'),
]
"@

# Navigate into the templates directory
cd "templates\$appName"
# Create base.html
# Create base.html with UTF-8 encoding
@"
{% load static %}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}My Django Project{% endblock %}</title>
    <link rel="stylesheet" href="{% static 'custom.css' %}">
    <!-- Bootstrap CSS -->
    <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css" rel="stylesheet">
    <!-- Custom CSS -->
    <style>
        body {
            padding-top: 70px;
        }
        .footer {
            position: fixed;
            bottom: 0;
            width: 100%;
            background-color: #f5f5f5;
            padding: 10px 0;
            text-align: center;
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark fixed-top">
        <div class="container">
            <a class="navbar-brand" href="#">DjangoApp</a>
            <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav">
                    <li class="nav-item active">
                        <a class="nav-link" href="#">Home <span class="sr-only">(current)</span></a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="#">Features</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="#">Pricing</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="#">About</a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container">
        {% block content %}
        <!-- Content will go here via child templates -->
        {% endblock %}
    </div>

    <div class="footer">
        <div class="container">
            <p class="text-muted">© 2024 My Django Project</p>
        </div>
    </div>

    <!-- Bootstrap JS, Popper.js, and jQuery -->
    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.5.2/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
</body>
</html>
"@ | Out-File "base.html" -Encoding utf8

# Create home.html with UTF-8 encoding
@"
{% extends 'appName/base.html' %}

{% block title %}Home{% endblock %}

{% block content %}
    <h1>Welcome to the Home Page</h1>
    <p>This is a simple Django-powered page automated by Ayoub Afi.</p>
    <p>THe aim of this project is to help you get started with Django quickly.</p>
    <p>Feel free to explore the site and check out the user list.</p>
    <h1>User List</h1>
    <ul>
        {% for user in users %}
        <li>{{ user.first_name }} {{ user.last_name }} - {{ user.email }}</li>
        {% endfor %}
    </ul>
{% endblock %}

"@ -replace "appName", $appName | Out-File "home.html" -Encoding utf8

# Navigate back to the project root directory
cd ../../..

# Navigate into the project directory to create the app
cd $projectName

# Path to the settings.py that needs to be updated
$settingsPath = "settings.py"

# Remove the existing settings.py file
Remove-Item $settingsPath

# Create a new settings.py file with the necessary configurations
@"
import os
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SECRET_KEY = '980328930293890uoiuYuyt&(Y&*^%&^&)989767yugy7'

DEBUG = True

ALLOWED_HOSTS = []

INSTALLED_APPS = [
    '$appName',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = '$projectName.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [os.path.join(BASE_DIR, 'templates')],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
    }
}
WSGI_APPLICATION = '$projectName.wsgi.application'


LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_L10N = True

USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')  # Collect static files here during production
STATICFILES_DIRS = [os.path.join(BASE_DIR, 'static')]  # In development, use this directory to find static files

"@ | Out-File $settingsPath -Encoding utf8

# Path to the urls.py that needs to be updated
$urlsPath = "urls.py"

# Remove the existing urls.py file
Remove-Item $urlsPath

# Create a new urls.py file with the necessary configurations
@"
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('$appName.urls')),
]
"@ | Out-File $urlsPath -Encoding utf8

# Navigate back to the project root
cd ..

# Create a directory for static files
New-Item -ItemType Directory -Path "static" -Force
# Create a custom CSS file in the static directory
@"
body {
    background-color: #f8f9fa;
    padding-top: 70px;

}
.navbar {
    border-bottom: 2px solid #dee2e6;
}

.footer {
    position: fixed;
    bottom: 0;
    width: 100%;
    background-color: #f5f5f5;
    padding: 10px 0;
    text-align: center;
}

h1 {
    color: #333;
}

h2 {
    color: #666;
}

p {
    color: #999;
}

"@ | Out-File -Encoding utf8 -FilePath "static/custom.css"

#create a faker file
@"
import os
import django
from faker import Faker

os.environ.setdefault('DJANGO_SETTINGS_MODULE', '$projectName.settings')
django.setup()

from $appName.models import User

def populate(N=10):
    fake = Faker()
    for _ in range(N):
        first_name = fake.first_name()
        last_name = fake.last_name()
        email = fake.email()
        User.objects.create(first_name=first_name, last_name=last_name, email=email)

if __name__ == '__main__':
    print("Populating the database...please wait.")
    populate(20)
    print("Populating complete.")

"@ | Out-File "generate_data.py" -Encoding utf8

# Make migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Generate some fake data
python generate_data.py
# Run the Django development server
python manage.py runserver

# Print instructions
Write-Host "Server is running on http://localhost:8000"
Write-Host "To stop the server, press CTRL+C"