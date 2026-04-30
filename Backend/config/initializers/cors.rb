# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
	allow do
		origins do |source, _env|
			allowed = if Rails.env.production?
				ENV.fetch("ALLOWED_CORS_ORIGINS", "https://app.aldervon.com").split(",").map(&:strip)
			else
				[
					"http://localhost:3000",
					"http://127.0.0.1:3000",
					"http://localhost:5173",
					"http://127.0.0.1:5173",
					"http://localhost:9090",
					"http://127.0.0.1:9090"
				]
			end
			allowed.include?(source)
		end

		resource "*",
						 headers: :any,
						 methods: %i[get post put patch delete options head]
	end
end
