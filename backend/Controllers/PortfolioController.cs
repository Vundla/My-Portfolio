using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PortfolioController : ControllerBase
{
    [HttpGet("projects")]
    public IActionResult GetProjects()
    {
        var projects = new[]
        {
            new { 
                Id = 1, 
                Name = "AI Study Buddy", 
                Description = "Interactive learning assistant leveraging AI",
                Technologies = new[] { "React", "AI/ML", "Node.js" },
                LiveDemo = "https://smart-learning-assistant-henna.vercel.app/",
                Features = new[] { "AI-powered tutoring", "Interactive learning", "Progress tracking" }
            },
            new { 
                Id = 2, 
                Name = "AI Resume Builder", 
                Description = "Web tool to generate professional AI-assisted resumes",
                Technologies = new[] { "Vue.js", "AI/ML", "PDF Generation" },
                LiveDemo = "https://vundla.github.io/ai-resume-builder/",
                Features = new[] { "AI content generation", "Professional templates", "Real-time preview" }
            },
            new { 
                Id = 3, 
                Name = "AI Sentiment Analyzer", 
                Description = "Analyzes text sentiment using AI models",
                Technologies = new[] { "Python", "NLP", "Machine Learning" },
                LiveDemo = "https://vundla.github.io/ai-sentiment-analyzer/",
                Features = new[] { "Real-time analysis", "Multiple AI models", "Visualization" }
            },
            new { 
                Id = 4, 
                Name = "Generative AI Project", 
                Description = "Tool to create AI-generated content dynamically",
                Technologies = new[] { "React", "OpenAI", "TypeScript" },
                LiveDemo = "https://vundla.github.io/My_Generative_AI_Project/",
                Features = new[] { "Content generation", "Multiple formats", "Customizable output" }
            },
            new { 
                Id = 5, 
                Name = "Azanian AI Agent", 
                Description = "AI chatbot providing interactive assistance",
                Technologies = new[] { "Chatbot Framework", "AI/ML", "WebSocket" },
                LiveDemo = "https://landbot.online/v3/H-2934706-7M0LMF0MKRD9B5FG/index.html",
                Features = new[] { "Natural language processing", "Context awareness", "Multi-turn conversations" }
            }
        };

        return Ok(projects);
    }

    [HttpGet("profile")]
    public IActionResult GetProfile()
    {
        var profile = new
        {
            Name = "Mandlenkosi Vundla",
            Title = "AI Developer & Software Engineer",
            Email = "vundlamandlenkosi0@gmail.com",
            GitHub = "https://github.com/vundla",
            LinkedIn = "https://www.linkedin.com/in/mandlenkosi-vundla-561666278/",
            Skills = new[] 
            { 
                "Artificial Intelligence", 
                "Machine Learning", 
                "Web Development", 
                "React", 
                "Python", 
                "JavaScript", 
                "C#", 
                ".NET",
                "Svelte",
                "Phoenix LiveView"
            },
            Experience = "Specializing in AI-driven applications and enterprise web solutions",
            Location = "Johannesburg, South Africa"
        };

        return Ok(profile);
    }

    [HttpGet("health")]
    public IActionResult Health()
    {
        return Ok(new { Status = "Healthy", Timestamp = DateTime.UtcNow });
    }
}