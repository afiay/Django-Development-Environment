# Get user input for environment, project, and app names
$envName = Read-Host "Enter the name of the virtual environment"
$projectName = Read-Host "Enter the name of your Django project"
$appName = Read-Host "Enter the name of your Django app"
# Get user input for superuser creation
$adminUsername = Read-Host "Enter the superuser's username"
$adminEmail = Read-Host "Enter the superuser's email"
$adminPassword = Read-Host "Enter the superuser's password" -AsSecureString

# Convert SecureString to plain text
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword)
$adminPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

Write-Host "Creating virtual environment..." -ForegroundColor Cyan
# Create a virtual environment
python -m venv $envName
Write-Host "Virtual environment created." -ForegroundColor Green

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
python-decouple
"@ | Out-File requirements.txt

# Install requirements from the requirements.txt file
Write-Host "Installing dependencies..." -ForegroundColor Cyan
pip install -r requirements.txt | Out-Null
Write-Host "Dependencies are installed." -ForegroundColor Green
# Start a new Django project
Write-Progress -Activity "Setting up Django" -Status "Initializing project and app" -PercentComplete 30
django-admin startproject $projectName .

# Create a new Django app
python manage.py startapp $appName



# Navigate into the app directory
cd "$appName"

# Create a templates directory and a subdirectory named after the app
New-Item -ItemType Directory -Path "templates\$appName" -Force | Out-Null

# Add content to views.py
Set-Content -Path "views.py" -Value @"
from django.shortcuts import render
from .models import User
from .forms import UserForm

def index(request):
    return render(request, '$appName/base.html')

def home_view(request):
    users = User.objects.all()
    return render(request, '$appName/home.html', {'users': users})

def form_view(request):
    if request.method == 'POST':
        form = UserForm(request.POST)
        if form.is_valid():
            form.save()
    else:
        form = UserForm()
    return render(request, '$appName/form.html', {'form': form})
"@

# add content to models.py
Set-Content -Path "models.py" -Value @"
from django.db import models
from django.contrib.auth.models import User
from django.utils.timezone import now

class Category(models.Model):
    name = models.CharField(max_length=255)
    slug = models.SlugField(max_length=255, unique=True)
    description = models.TextField(blank=True)

    class Meta:
        verbose_name_plural = 'Categories'

    def __str__(self):
        return self.name

class Product(models.Model):
    category = models.ForeignKey(Category, related_name='products', on_delete=models.CASCADE)
    name = models.CharField(max_length=255)
    slug = models.SlugField(max_length=255)
    description = models.TextField(blank=True, null=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    image = models.ImageField(upload_to='products/', blank=True, null=True)
    stock = models.PositiveIntegerField()
    available = models.BooleanField(default=True)
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

class Review(models.Model):
    product = models.ForeignKey(Product, related_name='reviews', on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    content = models.TextField()
    rating = models.IntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.user.username} on {self.product.name}'

class Wishlist(models.Model):
    user = models.ForeignKey(User, related_name='wishlist', on_delete=models.CASCADE)
    products = models.ManyToManyField(Product, related_name='wishlisted_by')

    def __str__(self):
        return f'{self.user.username}\'s Wishlist'

class Promotion(models.Model):
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    description = models.TextField()
    discount = models.DecimalField(max_digits=5, decimal_places=2)
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()

    def __str__(self):
        return f'Promotion for {self.product.name}'

class ShippingMethod(models.Model):
    name = models.CharField(max_length=100)
    cost = models.DecimalField(max_digits=6, decimal_places=2)
    time_to_delivery = models.CharField(max_length=50)  # Example: "3-5 business days"

    def __str__(self):
        return self.name

class Order(models.Model):
    user = models.ForeignKey(User, related_name='orders', on_delete=models.CASCADE)
    ref_code = models.CharField(max_length=20)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    paid = models.BooleanField(default=False)
    payment_id = models.CharField(max_length=100, blank=True, null=True)
    shipping_method = models.ForeignKey(ShippingMethod, null=True, on_delete=models.SET_NULL)

    class Meta:
        ordering = ('-created_at',)

    def __str__(self):
        return f'Order {self.ref_code}'

class OrderItem(models.Model):
    order = models.ForeignKey(Order, related_name='items', on_delete=models.CASCADE)
    product = models.ForeignKey(Product, related_name='order_items', on_delete=models.CASCADE)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    quantity = models.PositiveIntegerField(default=1)

    def __str__(self):
        return str(self.id)

class Address(models.Model):
    user = models.ForeignKey(User, related_name='addresses', on_delete=models.CASCADE)
    street_address = models.CharField(max_length=100)
    apartment_address = models.CharField(max_length=100)
    zip = models.CharField(max_length=20)
    city = models.CharField(max_length=100)
    country = models.CharField(max_length=100)
    address_type = models.CharField(max_length=1, choices=[('S', 'Shipping'), ('B', 'Billing')])

    def __str__(self):
        return f'{self.street_address}, {self.apartment_address}, {self.zip}, {self.city}, {self.country}'

class Payment(models.Model):
    stripe_charge_id = models.CharField(max_length=50)
    user = models.ForeignKey(User, related_name='payments', on_delete=models.SET_NULL, null=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.stripe_charge_id


"@
Set-Content -Path "admin.py" -Value @"
from django.contrib import admin
from .models import Category, Product, Review, Wishlist, Promotion, ShippingMethod, Order, OrderItem, Address, Payment

class CategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'slug']
    prepopulated_fields = {'slug': ('name',)}

admin.site.register(Category, CategoryAdmin)

class ProductAdmin(admin.ModelAdmin):
    list_display = ['name', 'category', 'price', 'stock', 'available', 'created', 'updated']
    list_filter = ['available', 'created', 'updated', 'category']
    list_editable = ['price', 'stock', 'available']
    prepopulated_fields = {'slug': ('name',)}

admin.site.register(Product, ProductAdmin)

class ReviewAdmin(admin.ModelAdmin):
    list_display = ['product', 'user', 'rating', 'created_at']
    list_filter = ['created_at', 'user', 'rating']
    search_fields = ['content', 'user__username', 'product__name']

admin.site.register(Review, ReviewAdmin)

class WishlistAdmin(admin.ModelAdmin):
    list_display = ['user']
    filter_horizontal = ['products']

admin.site.register(Wishlist, WishlistAdmin)

class PromotionAdmin(admin.ModelAdmin):
    list_display = ['product', 'description', 'discount', 'start_date', 'end_date']
    list_filter = ['start_date', 'end_date']
    search_fields = ['description', 'product__name']

admin.site.register(Promotion, PromotionAdmin)

class ShippingMethodAdmin(admin.ModelAdmin):
    list_display = ['name', 'cost', 'time_to_delivery']

admin.site.register(ShippingMethod, ShippingMethodAdmin)

class OrderAdmin(admin.ModelAdmin):
    list_display = ['ref_code', 'user', 'paid', 'created_at', 'updated_at', 'shipping_method']
    list_filter = ['paid', 'created_at', 'updated_at']
    search_fields = ['ref_code', 'user__username']

admin.site.register(Order, OrderAdmin)

class OrderItemAdmin(admin.ModelAdmin):
    list_display = ['order', 'product', 'price', 'quantity']
    search_fields = ['order__ref_code', 'product__name']

admin.site.register(OrderItem, OrderItemAdmin)

class AddressAdmin(admin.ModelAdmin):
    list_display = ['user', 'street_address', 'city', 'zip', 'country', 'address_type']
    list_filter = ['country', 'address_type']
    search_fields = ['city', 'street_address', 'zip']

admin.site.register(Address, AddressAdmin)

class PaymentAdmin(admin.ModelAdmin):
    list_display = ['stripe_charge_id', 'user', 'amount', 'timestamp']
    search_fields = ['stripe_charge_id', 'user__username']

admin.site.register(Payment, PaymentAdmin)

"@
# Create urls.py and add content
Set-Content -Path "urls.py" -Value @"
from django.urls import path

from . import views

urlpatterns = [
    path('', views.home_view, name='home'),
    # form view
    path('form/', views.form_view, name='form'),
]
"@

# Create urls.py and add content
Set-Content -Path "forms.py" -Value @"
from django import forms
from .models import User

class UserForm(forms.ModelForm):
    class Meta:
        model = User
        fields = ['first_name', 'last_name', 'email']
        widgets = {
            'first_name': forms.TextInput(attrs={'class': 'form-control'}),
            'last_name': forms.TextInput(attrs={'class': 'form-control'}),
            'email': forms.EmailInput(attrs={'class': 'form-control'}),
        }
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
    <title>{% block title %}$projectName{% endblock %}</title>
    <link rel="stylesheet" href="{% static 'custom.css' %}">
    <!-- Bootstrap CSS -->
    <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark fixed-top">
        <div class="container">
            <a class="navbar-brand" href="#">$appName</a>
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

{% block title %}Welcome Home{% endblock %}

{% block content %}
<div class="container mt-5">
    <h1 class="display-4">Welcome to the Home Page</h1>
    <p class="lead">This is a simple Django-powered page automated by Ayoub Afi.</p>
    <p>The aim of this project is to help you get started with Django quickly and efficiently.</p>
    <p>Feel free to explore the site and check out the list of users below.</p>
    

    <h2 class="mt-4">User List</h2>
    <div class="list-group">
        {% for user in users %}
        <a href="#" class="list-group-item list-group-item-action">
            {{ user.first_name }} {{ user.last_name }} - {{ user.email }}
        </a>
        {% endfor %}
    </div>
</div>
{% endblock %}

"@ -replace "appName", $appName | Out-File "home.html" -Encoding utf8

# Form.html
@"
{% extends 'appName/base.html' %}

{% block title %}Add User{% endblock %}


{% block content %}
<div class="container mt-5">
    <h1 class="display-4">Add a New User</h1>
    <p class="lead">Use the form below to add a new user to the database.</p>
    <form method="POST">
        {% csrf_token %}
        {{ form.as_p }}
        <button type="submit" class="btn btn-primary">Add User</button>
    </form>
</div>
{% endblock %}
"@ -replace "appName", $appName | Out-File "form.html" -Encoding utf8
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
from decouple import config

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SECRET_KEY = config('SECRET_KEY')
DEBUG = config('DEBUG', default=False, cast=bool)
ALLOWED_HOSTS = config('ALLOWED_HOSTS', cast=lambda v: [s.strip() for s in v.split(',')])

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

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_L10N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
STATICFILES_DIRS = [os.path.join(BASE_DIR, 'static')]

# Media settings
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

"@ | Out-File $settingsPath -Encoding utf8

# Path to the urls.py that needs to be updated
$urlsPath = "urls.py"

# Remove the existing urls.py file
Remove-Item $urlsPath

# Create a new urls.py file with the necessary configurations
@"
from django.contrib import admin
from django.urls import include, path
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('$appName.urls')),
]+ static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

"@ | Out-File $urlsPath -Encoding utf8

# Navigate back to the project root
cd ..

# Create a directory for static files
New-Item -ItemType Directory -Path "static" -Force
# Create a custom CSS file in the static directory
@"
/* General body styles */
body {
    font-family: 'Arial', sans-serif; /* Ensures a clean, modern font is used */
    background-color: #f4f4f9; /* Light grey background for a softer look */
    color: #333; /* Dark grey text for better readability */
}

/* Navbar tweaks for better visual separation */
.navbar {
    background-color: #0056b3; /* A deeper blue for contrast */
    box-shadow: 0 2px 4px rgba(0,0,0,.1); /* Subtle shadow for depth */
}

/* Main container adjustments */
.container {
    padding-top: 2rem; /* More space on the top inside the container */
    padding-bottom: 2rem; /* More space at the bottom for separation */
}

/* Headings styling */
h1.display-4 {
    font-size: 2.5rem; /* More appropriate size for desktop and mobile */
    color: #004085; /* Dark blue for a professional look */
}

h2 {
    color: #0056b3; /* Consistent theme color for headings */
    margin-bottom: 1rem; /* Space below subheadings */
}

/* Paragraph text styling */
p.lead {
    font-size: 1.1rem; /* Slightly larger for lead paragraphs */
    color: #555; /* Soft black for less harshness */
}

/* User list styles */
.list-group-item {
    background-color: #fff; /* White background for list items */
    border-left: 3px solid #007bff; /* Blue accent on the left for visual interest */
    margin-bottom: .5rem; /* Space between list items */
}

.list-group-item-action:hover {
    background-color: #f8f9fa; /* Light feedback on hover */
}

/* Link styling */
a {
    color: #0056b3; /* Links styled with theme color */
    text-decoration: none; /* No underline for a cleaner look */
}

a:hover {
    color: #004185; /* Darker blue on hover for distinction */
}

"@ | Out-File -Encoding utf8 -FilePath "static/custom.css"

#create a faker file
@"
import os
import django
from faker import Faker
from decimal import Decimal
from random import randint, choice
from django.utils import timezone

os.environ.setdefault('DJANGO_SETTINGS_MODULE', '$projectName.settings')
django.setup()


from django.contrib.auth.models import User
from $appName.models import Category, Product, Review, Wishlist, Promotion, ShippingMethod, Order, OrderItem, Address, Payment


fake = Faker()

def create_categories(n):
    for _ in range(n):
        Category.objects.create(
            name=fake.word(),
            slug=fake.slug(),
            description=fake.text()
        )

def create_products(n):
    categories = list(Category.objects.all())
    for _ in range(n):
        category = choice(categories)
        Product.objects.create(
            category=category,
            name=fake.word(),
            slug=fake.slug(),
            description=fake.text(),
            price=Decimal(randint(100, 10000) / 100),
            stock=randint(1, 100),
            available=choice([True, False]),
            image=None  # Assume no image files are being uploaded
        )

def create_reviews(n):
    users = list(User.objects.all())
    products = list(Product.objects.all())
    for _ in range(n):
        Review.objects.create(
            product=choice(products),
            user=choice(users),
            content=fake.text(),
            rating=randint(1, 5),
            created_at=timezone.now()
        )

def create_wishlists(n):
    users = list(User.objects.all())
    products = list(Product.objects.all())
    for _ in range(n):
        wishlist, created = Wishlist.objects.get_or_create(user=choice(users))
        wishlist.products.add(choice(products))

def create_promotions(n):
    products = list(Product.objects.all())
    for _ in range(n):
        start_date = timezone.now() + timezone.timedelta(days=randint(1, 10))
        end_date = start_date + timezone.timedelta(days=randint(1, 30))
        Promotion.objects.create(
            product=choice(products),
            description=fake.text(),
            discount=Decimal(randint(5, 95) / 100),
            start_date=start_date,
            end_date=end_date
        )

def create_shipping_methods(n):
    for _ in range(n):
        ShippingMethod.objects.create(
            name=fake.word(),
            cost=Decimal(randint(200, 2000) / 100),
            time_to_delivery=f"{randint(1, 10)}-5 business days"
        )

def create_orders(n):
    users = list(User.objects.all())
    shipping_methods = list(ShippingMethod.objects.all())
    for _ in range(n):
        order = Order.objects.create(
            user=choice(users),
            ref_code=fake.lexify(text='????-????-????'),
            shipping_method=choice(shipping_methods),
            paid=choice([True, False]),
            payment_id=fake.uuid4() if choice([True, False]) else None
        )
        create_order_items(order, randint(1, 5))

def create_order_items(order, n):
    products = list(Product.objects.all())
    for _ in range(n):
        product = choice(products)
        OrderItem.objects.create(
            order=order,
            product=product,
            price=product.price,
            quantity=randint(1, 5)
        )

def create_addresses(n):
    users = list(User.objects.all())
    for _ in range(n):
        Address.objects.create(
            user=choice(users),
            street_address=fake.street_address(),
            apartment_address=fake.secondary_address(),
            zip=fake.zipcode(),
            city=fake.city(),
            country=fake.country(),
            address_type=choice(['S', 'B'])
        )

def create_payments(n):
    users = list(User.objects.all())
    for _ in range(n):
        Payment.objects.create(
            stripe_charge_id=fake.uuid4(),
            user=choice(users),
            amount=Decimal(randint(1000, 50000) / 100),
            timestamp=timezone.now()
        )

if __name__ == "__main__":
    create_categories(10)
    create_products(50)
    create_reviews(200)
    create_wishlists(30)
    create_promotions(15)
    create_shipping_methods(5)
    create_orders(20)  # This will also create order items
    create_addresses(40)
    create_payments(20)

"@ | Out-File "generate_data.py" -Encoding utf8



#--------------------------------------------

#create a faker file
@"
DEBUG=True
SECRET_KEY=980328930293890uoiuYuyt&(Y&*^%&^&)989767yugy7
DEBUG=True
ALLOWED_HOSTS=.localhost,127.0.0.1
DATABASE_URL=sqlite:///db.sqlite3

"@ | Out-File ".env" -Encoding utf8

#--------------------------------------------
# Make migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate


# Create the superuser using Django's manage.py
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('$adminUsername', '$adminEmail', '$adminPassword')" | python manage.py shell

Write-Host "Superuser created successfully." -ForegroundColor Green

# Wait for 2 seconds
Start-Sleep -Seconds 2
# Generate some fake data
python generate_data.py

# Wait for 5 seconds
Start-Sleep -Seconds 5


# Completing setup
Write-Host "$projectName created successfully." -ForegroundColor Green

# Run the Django development server
python manage.py runserver

# Print instructions
Write-Host "Server is running on http://localhost:8000" -ForegroundColor Green
Write-Host "To stop the server, press CTRL+C"
