db.createCollection("User", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["name", "email", "password"],
         properties: {
            name: {
               bsonType: "string",
               description: "Must be a string and is required"
            },
            email: {
               bsonType: "string",
               pattern: "^.+@.+$",
               description: "Must be a valid email address and is required"
            },
            password: {
               bsonType: "string",
               description: "Must be an encrypted string and is required"
            }
         }
      }
   }
})

# Database Collections List

1. user
2. calendar_events
3. email
4. devices
5. active_time
6. sleep_time
7. environment_data
8. ai_predictions