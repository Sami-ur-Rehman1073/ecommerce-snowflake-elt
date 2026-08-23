import os
import random
from datetime import datetime, timedelta

import pandas as pd
from faker import Faker


fake = Faker()
random.seed(42)
Faker.seed(42)


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data")

os.makedirs(DATA_DIR, exist_ok=True)


# --------------------------------------------------
# CONFIGURATION
# --------------------------------------------------

NUM_CUSTOMERS = 100
NUM_PRODUCTS = 50
NUM_ORDERS = 500


CATEGORIES = [
    "Electronics",
    "Clothing",
    "Home",
    "Books",
    "Sports"
]


ORDER_STATUSES = [
    "COMPLETED",
    "COMPLETED",
    "COMPLETED",
    "PENDING",
    "CANCELLED"
]


# --------------------------------------------------
# CUSTOMERS
# --------------------------------------------------

customers = []

for customer_id in range(1, NUM_CUSTOMERS + 1):

    customers.append({
        "customer_id": customer_id,
        "customer_name": fake.name(),
        "email": fake.email(),
        "city": fake.city(),
        "country": "Pakistan"
    })


customers_df = pd.DataFrame(customers)


# --------------------------------------------------
# PRODUCTS
# --------------------------------------------------

product_names = [
    "Laptop",
    "Smartphone",
    "Headphones",
    "Keyboard",
    "Mouse",
    "Monitor",
    "T-Shirt",
    "Jeans",
    "Jacket",
    "Shoes",
    "Backpack",
    "Novel",
    "Notebook",
    "Desk Lamp",
    "Football",
    "Cricket Bat",
    "Water Bottle",
    "Smart Watch",
    "Tablet",
    "Power Bank"
]


products = []

for product_id in range(1, NUM_PRODUCTS + 1):

    products.append({
        "product_id": product_id,
        "product_name": f"{random.choice(product_names)} {product_id}",
        "category": random.choice(CATEGORIES),
        "unit_price": round(random.uniform(10, 1000), 2)
    })


products_df = pd.DataFrame(products)


# --------------------------------------------------
# ORDERS
# --------------------------------------------------

orders = []

start_date = datetime(2026, 1, 1)

for order_id in range(1, NUM_ORDERS + 1):

    order_date = start_date + timedelta(
        days=random.randint(0, 230)
    )

    orders.append({
        "order_id": order_id,
        "customer_id": random.randint(1, NUM_CUSTOMERS),
        "order_date": order_date.strftime("%Y-%m-%d"),
        "status": random.choice(ORDER_STATUSES)
    })


orders_df = pd.DataFrame(orders)


# --------------------------------------------------
# ORDER ITEMS
# --------------------------------------------------

order_items = []

for order_id in range(1, NUM_ORDERS + 1):

    number_of_items = random.randint(1, 5)

    selected_products = random.sample(
        range(1, NUM_PRODUCTS + 1),
        number_of_items
    )

    for product_id in selected_products:

        product_price = products_df.loc[
            products_df["product_id"] == product_id,
            "unit_price"
        ].iloc[0]

        order_items.append({
            "order_id": order_id,
            "product_id": product_id,
            "quantity": random.randint(1, 5),
            "unit_price": product_price
        })


order_items_df = pd.DataFrame(order_items)


# --------------------------------------------------
# SAVE CSV FILES
# --------------------------------------------------

customers_df.to_csv(
    os.path.join(DATA_DIR, "customers.csv"),
    index=False
)

products_df.to_csv(
    os.path.join(DATA_DIR, "products.csv"),
    index=False
)

orders_df.to_csv(
    os.path.join(DATA_DIR, "orders.csv"),
    index=False
)

order_items_df.to_csv(
    os.path.join(DATA_DIR, "order_items.csv"),
    index=False
)


# --------------------------------------------------
# SUMMARY
# --------------------------------------------------

print("E-commerce data generated successfully.")

print(f"Customers: {len(customers_df)}")
print(f"Products: {len(products_df)}")
print(f"Orders: {len(orders_df)}")
print(f"Order items: {len(order_items_df)}")

print(f"\nFiles saved to: {DATA_DIR}")