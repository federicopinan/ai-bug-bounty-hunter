# Hunter — Bug Bounty Hunting Environment

AI-assisted security research framework. Contains prompt templates for automated vulnerability research.

## Directory Structure

```
hunter/
├── README.md              # Este archivo
├── prompts/               # Plantillas de prompts para IA
│   ├── source-code.md     # Análisis de código fuente
│   ├── binary.md          # Análisis de ejecutables/binarios
│   └── web-app.md         # Análisis de aplicaciones web
├── programs/              # Programas/objetivos a auditar
├── reports/               # Reportes de vulnerabilidades generados
├── tools/                 # Scripts y herramientas propias
├── config/                # Configuraciones y guías de programas
└── docs/                  # Documentación general
```

## Uso

1. Agregar programa a auditar en `programs/`
2. Crear/editar `config/[programa]-scope.md` con las reglas del programa
3. Usar el prompt correspondiente en `prompts/` como base
4. Los reportes se guardan en `reports/`