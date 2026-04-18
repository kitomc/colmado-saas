# PROMPT_MAESTRO.md — Cómo iniciar cada sesión de OpenCode

> Copia y pega este bloque al INICIO de cada sesión de OpenCode.
> Reemplaza los valores entre [corchetes] según tu situación actual.

---

## Prompt de inicio de sesión (copiar tal cual):

```
Lee completamente estos archivos en este orden antes de responder cualquier cosa:
1. AGENTS.md
2. POC_ColmadoAI_SaaS.md
3. checklists/fase[N].md (la fase actual)

Contexto de la sesión actual:
- Fase actual: [NÚMERO Y NOMBRE DE LA FASE]
- Nano-tarea a implementar: [NÚMERO Y NOMBRE DE LA NANO-TAREA]
- Último ítem verificado: [ÚLTIMO ÍTEM MARCADO EN EL CHECKLIST]
- Archivos relevantes ya existentes: [LISTA DE ARCHIVOS YA CREADOS]

Instrucciones para esta sesión:
1. Ejecuta el Chain of Thought del AGENTS.md internamente antes de escribir código.
2. Implementa ÚNICAMENTE la nano-tarea indicada arriba.
3. Escribe el código completo del archivo correspondiente.
4. Debajo del código, escribe los pasos exactos para verificarlo.
5. DETENTE y espera mi confirmación antes de pasar a la siguiente nano-tarea.

Nano-tarea a implementar ahora:
[DESCRIPCIÓN DETALLADA DE LO QUE NECESITAS]
```

---

## Ejemplos de uso por fase:

### Inicio de Fase 1, Nano 1.1:
```
Lee completamente estos archivos en este orden antes de responder cualquier cosa:
1. AGENTS.md
2. POC_ColmadoAI_SaaS.md
3. checklists/fase1.md

Contexto de la sesión actual:
- Fase actual: Fase 1 — Fundamentos del Backend
- Nano-tarea a implementar: Nano 1.1 — Schema tabla colmados
- Último ítem verificado: Ninguno, comenzamos desde cero
- Archivos relevantes ya existentes: Ninguno

Instrucciones para esta sesión:
1. Ejecuta el Chain of Thought del AGENTS.md internamente antes de escribir código.
2. Implementa ÚNICAMENTE la nano-tarea indicada arriba.
3. Escribe el código completo del archivo correspondiente.
4. Debajo del código, escribe los pasos exactos para verificarlo.
5. DETENTE y espera mi confirmación antes de pasar a la siguiente nano-tarea.

Nano-tarea a implementar ahora:
Crea el archivo convex/schema.ts con ÚNICAMENTE la tabla "colmados".
Los campos son: nombre (string), telefono_whatsapp (string), telegram_chat_id (string opcional),
whatsapp_token (string), activo (boolean), created_at (number).
Aplica principio S de SOLID: el schema de colmados no debe mezclar lógica de otros dominios.
```

### Inicio de Fase 2, Nano 2.4 (continuación):
```
Lee completamente estos archivos en este orden:
1. AGENTS.md
2. checklists/fase2.md

Contexto:
- Fase actual: Fase 2 — Webhook y Agente LLM
- Nano-tarea: Nano 2.4 — Llamada a DeepSeek V3.2 desde Convex Action
- Último ítem verificado: Nano 2.3 ✅ — Parser de payload WhatsApp funcionando
- Archivos existentes: convex/schema.ts, convex/http.ts (con el parser)

Instrucciones para esta sesión:
1. Ejecuta el Chain of Thought internamente.
2. Implementa SOLO la función que llama a DeepSeek dentro del archivo convex/http.ts existente.
3. No modifiques nada del parser ya implementado (principio O de SOLID).
4. Escribe la verificación exacta.
5. DETENTE.

Nano-tarea:
Implementa la función privada `llamarDeepSeek(historial, systemPrompt)` que:
- Recibe el array de mensajes del historial y el system prompt
- Llama a https://api.deepseek.com/v1/chat/completions
- Usa el modelo "deepseek-chat"
- Maneja el timeout de 8 segundos
- Retorna el string de la respuesta del LLM
- Si la respuesta es un JSON de orden, lo detecta y lo retorna como objeto parseado
```

---

## Protocolo cuando el modelo comete un error:

Cuando OpenCode produce código con errores, usa este prompt de corrección:

```
El código anterior produjo este error:
[PEGAR EL ERROR EXACTO CON EL STACK TRACE]

Antes de corregir, ejecuta el Chain of Thought desde el PASO 1 para este error.
Identifica la causa raíz, no el síntoma.
Corrige ÚNICAMENTE la línea o función que causó el error.
No refactorices nada más.
Explica en una línea qué causó el error y cómo lo corregiste.
```

---

## Protocolo cuando necesitas validar una nano-tarea completa:

```
Acabo de verificar la nano-tarea [NÚMERO]: [lo que hiciste].
Resultados de la verificación:
[✅ o ❌] [ítem 1]
[✅ o ❌] [ítem 2]
[✅ o ❌] [ítem 3]

[Si todo ✅]: Marca los ítems en el checklist y dime cuál es la siguiente nano-tarea exacta a implementar.
[Si hay ❌]: Analiza solo el ítem que falló y propón la corrección mínima necesaria.
```
