# CLAUDE.md - Technical Notes for LLM Council

This file contains technical details, architectural decisions, and important implementation notes for future development sessions.

## Quick Start - Resuming Development

### Local Development
```bash
# Backend (from project root)
uv run python -m backend.main

# Frontend (in separate terminal)
cd frontend && npm run dev
```
Then open http://localhost:5174 (or 5173 if available)

### Deploying Changes
```bash
# Commit and push to GitHub
git add -A && git commit -m "Your message" && git push

# Redeploy frontend to Vercel
cd frontend && vercel --prod --yes

# Backend auto-deploys on Railway when you push to GitHub
```

## Deployment URLs

| Service | URL | Platform |
|---------|-----|----------|
| **Frontend** | https://frontend-rfe31sw23-ben-reeders-projects.vercel.app | Vercel |
| **Backend API** | https://llm-council-production-a448.up.railway.app | Railway |
| **GitHub Repo** | https://github.com/benreeder-coder/llm-council | GitHub |

## Environment Variables

### Local Development
Create `.env` in project root:
```
OPENROUTER_API_KEY=sk-or-v1-your-key-here
```

### Production (Railway)
Set in Railway dashboard: Project → Service → **Variables** tab
- `OPENROUTER_API_KEY` - Your OpenRouter API key

**IMPORTANT**: The `.env` file is gitignored and NOT deployed. Railway needs the variable set in its dashboard.

## Current Model Configuration

Edit `backend/config.py` to change models:

```python
COUNCIL_MODELS = [
    "openai/gpt-5.2",
    "google/gemini-3-pro-preview",
    "anthropic/claude-opus-4.5",
]

CHAIRMAN_MODEL = "anthropic/claude-opus-4.5"
```

### Model Costs (OpenRouter)
- **Claude Opus 4.5**: $3/M input, $15/M output (expensive)
- **GPT-5.2**: ~$2.50/M input, $10/M output
- **Gemini 3 Pro**: ~$1.25/M input, $5/M output
- **Gemini 3 Flash**: Much cheaper, good for chairman if budget-conscious

Check current prices: https://openrouter.ai/models

## Project Overview

LLM Council is a 3-stage deliberation system where multiple LLMs collaboratively answer user questions. The key innovation is anonymized peer review in Stage 2, preventing models from playing favorites.

### The 3 Stages
1. **Stage 1**: All council models answer the question independently (parallel)
2. **Stage 2**: Each model ranks the others' responses (anonymized as Response A, B, C)
3. **Stage 3**: Chairman synthesizes all responses + rankings into final answer

## Architecture

### Backend Structure (`backend/`)

| File | Purpose |
|------|---------|
| `config.py` | Model configuration, API keys, constants |
| `openrouter.py` | OpenRouter API client with error handling |
| `council.py` | Core 3-stage logic, ranking parser |
| `storage.py` | JSON conversation persistence |
| `main.py` | FastAPI routes, CORS config |

**Key Backend Notes:**
- Backend runs on **port 8001**
- CORS allows all origins (`"*"`) for deployment flexibility
- Chairman has 180s timeout (longer for synthesis)
- Errors are logged with full response body for debugging

### Frontend Structure (`frontend/src/`)

| File | Purpose |
|------|---------|
| `App.jsx` | Main app, conversation state management |
| `api.js` | Backend API client (uses `VITE_API_URL` env var) |
| `index.css` | Global styles, CSS variables, animations |
| `components/ChatInterface.jsx` | Chat UI, input form, loading states |
| `components/Stage1.jsx` | Individual response tabs |
| `components/Stage2.jsx` | Rankings, aggregate scores |
| `components/Stage3.jsx` | Chairman's final answer |

## Design System - "Neural Command Center"

The frontend uses a futuristic dark theme with orange accents.

### CSS Variables (in `index.css`)
```css
--bg-primary: #050508;          /* Near-black background */
--bg-secondary: #0a0a0f;        /* Slightly lighter */
--orange-primary: #FF6B00;      /* Main accent */
--orange-secondary: #FF8C00;    /* Warm orange */
--orange-glow: rgba(255, 107, 0, 0.4);
--text-primary: #ffffff;
--text-secondary: #b0b0b0;
--font-display: 'Orbitron', sans-serif;  /* Headers */
--font-body: 'JetBrains Mono', monospace; /* Body text */
```

### Key Visual Features
- Dark background with subtle orange grid pattern
- Glassmorphism panels with transparency
- Glowing orange accents on hover/focus
- Smooth animations: fade-in, slide-in, pulse, scan-line
- Stage badges (01, 02, 03) for each phase
- Trophy icon for rankings, crown for chairman

### Changing the Theme
1. Edit CSS variables in `frontend/src/index.css`
2. Component-specific styles in `frontend/src/components/*.css`
3. Commit, push, and redeploy to Vercel

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/conversations` | List all conversations |
| POST | `/api/conversations` | Create new conversation |
| GET | `/api/conversations/{id}` | Get conversation details |
| POST | `/api/conversations/{id}/message` | Send message (batch) |
| POST | `/api/conversations/{id}/message/stream` | Send message (streaming) |

## Common Tasks

### Adding a New Model to the Council
1. Find the model ID on https://openrouter.ai/models
2. Edit `backend/config.py`:
   ```python
   COUNCIL_MODELS = [
       "openai/gpt-5.2",
       "your-new/model-id",  # Add here
       ...
   ]
   ```
3. Commit, push (Railway auto-deploys)

### Changing the Chairman
Edit `backend/config.py`:
```python
CHAIRMAN_MODEL = "google/gemini-3-flash-preview"  # Cheaper option
```

### Updating Frontend API URL
For local dev, the frontend uses `http://localhost:8001`.
For production, set in `frontend/.env.production`:
```
VITE_API_URL=https://llm-council-production-a448.up.railway.app
```

## Troubleshooting

### "Unable to generate final synthesis" Error
- Check OpenRouter credits at https://openrouter.ai/credits
- Check Railway logs: Project → Service → Deployments → View Logs
- Verify `OPENROUTER_API_KEY` is set in Railway Variables

### 401 "No cookie auth credentials found"
- API key not set in Railway
- Go to Railway: Project → Service → Variables → Add `OPENROUTER_API_KEY`

### CORS Errors
- Backend CORS is set to `"*"` (all origins)
- If issues persist, check `backend/main.py` CORS middleware

### Models Timing Out
- Increase timeout in `backend/openrouter.py` (default 120s)
- Chairman has 180s timeout in `backend/council.py`

## Data Flow

```
User Query
    ↓
Stage 1: Parallel queries → [individual responses]
    ↓
Stage 2: Anonymize → Parallel ranking queries → [evaluations + parsed rankings]
    ↓
Aggregate Rankings Calculation → [sorted by avg position]
    ↓
Stage 3: Chairman synthesis with full context (180s timeout)
    ↓
Return: {stage1, stage2, stage3, metadata}
    ↓
Frontend: Display with tabs + validation UI
```

## File Structure

```
llm-council/
├── backend/
│   ├── __init__.py
│   ├── config.py          # Models, API key
│   ├── council.py         # 3-stage logic
│   ├── main.py            # FastAPI app
│   ├── openrouter.py      # API client
│   └── storage.py         # JSON storage
├── frontend/
│   ├── src/
│   │   ├── components/    # React components
│   │   ├── api.js         # API client
│   │   ├── App.jsx        # Main app
│   │   ├── App.css
│   │   └── index.css      # Global styles, theme
│   ├── .env.production    # Production API URL
│   └── package.json
├── .env                   # Local API key (gitignored)
├── .gitignore
├── CLAUDE.md              # This file
├── Dockerfile             # Railway deployment
├── pyproject.toml         # Python dependencies
├── railway.json           # Railway config
└── README.md
```

## Future Enhancement Ideas

- [ ] Configurable council/chairman via UI
- [ ] Streaming responses (show as they come in)
- [ ] Export conversations to markdown/PDF
- [ ] Model performance analytics
- [ ] Custom ranking criteria
- [ ] Cost tracking per query
- [ ] User authentication
- [ ] Multiple council presets
