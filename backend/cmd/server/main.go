package main

import (
	"log"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
)

func main() {
	// Create Fiber app
	app := fiber.New(fiber.Config{
		AppName: "SIGAP Backend v0.1.0",
	})

	// Middleware
	app.Use(logger.New())
	app.Use(cors.New())

	// Routes
	app.Get("/health", healthCheck)
	app.Get("/", welcome)

	// Start server
	log.Println("🚀 Server starting on :8080")
	if err := app.Listen(":8080"); err != nil {
		log.Fatal(err)
	}
}

func healthCheck(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"status": "ok",
		"message": "SIGAP Backend is running",
	})
}

func welcome(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"app": "SIGAP Backend",
		"version": "0.1.0",
		"status": "setup phase",
	})
}
