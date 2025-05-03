# Library Booking System Backend



##  Structure

```
backend/
├── models/          # Data models representing our core entities
│   ├── room.dart    # Room model with capacity and availability info
│   └── booking.dart # Booking model with time slots and status
├── services/        # Services handling business logic and Firebase interactions
    ├── auth_service.dart    # Authentication service for admin access
    └── database_service.dart # Database operations for rooms and bookings

```

## Code Organization

### Models


- **Room Model**: Represents a library room with properties like capacity and name
- **Booking Model**: Handles room reservations with time slots and status tracking

### Services


- **Auth Service**: Manages admin authentication using Firebase custom tokens
- **Database Service**: Handles all Firestore operations for rooms and bookings

## Key Features

1. **Real-time Updates**: Using Firebase streams for live data
2. **Booking Management**: Complete booking lifecycle handling
3. **Statistics Tracking**: Real-time analytics for room usage


