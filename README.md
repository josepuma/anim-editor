# Sistema de Scripts JavaScript para Efectos de Partículas

Esta extensión permite a los usuarios crear y personalizar efectos de partículas mediante scripts JavaScript, sin necesidad de modificar el código base de la aplicación.

## Características principales

- **Creación de efectos personalizados** mediante scripts JavaScript
- **Interfaz visual** para editar parámetros de efectos
- **Plantillas predefinidas** para efectos comunes (lluvia, fuego, etc.)
- **Edición en tiempo real** de parámetros
- **Biblioteca de API** para interactuar con el sistema de partículas

## Estructura del sistema

El sistema consta de varias clases clave:

1. **JSInterpreter**: Núcleo del sistema que proporciona la integración con JavaScriptCore.
2. **ParticleScriptManager**: Gestiona la carga, ejecución y almacenamiento de scripts.
3. **ScriptPanel**: Interfaz para seleccionar y administrar scripts.
4. **ScriptParametersPanel**: Interfaz para editar parámetros de scripts.

## Cómo crear un script de efectos

Los scripts de efectos deben seguir una estructura específica:

```javascript
// Parámetros configurables del efecto
var params = {
    startTime: 0,
    endTime: 10000,
    intensity: 50,
    // ...otros parámetros
};

// Función de inicialización (se llama al cargar el script)
function init() {
    console.log("Script cargado");
}

// Función principal (crea el efecto)
function main() {
    // Configuración del emisor
    var settings = {
        texture: "path/to/texture.png",
        // ...configuración del efecto
    };
    
    // Crear el efecto
    ParticleAPI.createParticleEffect("EffectName", settings);
    
    // Exponer parámetros para la UI
    ParticleAPI.defineParameters("EffectName", {
        // Parámetros que se mostrarán en la UI
    });
}

// Función para obtener parámetros (llamada por la UI)
function getParameters() {
    return params;
}

// Función para actualizar un parámetro (llamada por la UI)
function updateParameter(name, value) {
    params[name] = value;
}
```

## API JavaScript disponible

Los scripts tienen acceso a las siguientes funciones a través del objeto `ParticleAPI`:

- **ParticleAPI.createParticleEffect(name, settings)**: Crea un nuevo efecto de partículas.
- **ParticleAPI.defineParameters(effectName, parameters)**: Define los parámetros editables.
- **ParticleAPI.getCurrentTime()**: Obtiene el tiempo actual en milisegundos.

## Configuración de efectos

Los scripts pueden configurar numerosos aspectos de los efectos de partículas:

### Configuración básica
- `texture`: Ruta a la textura de partícula
- `startTime`: Tiempo de inicio (ms)
- `endTime`: Tiempo de finalización (ms)
- `particleCount`: Cantidad de partículas
- `emissionMode`: Modo de emisión ("continuous", "burst", "controlled")

### Forma de emisión
- `emissionShape`: Tipo de forma ("point", "line", "circle", "rectangle")
- Parámetros específicos según la forma (posición, radio, etc.)

### Propiedades de movimiento
- `initialVelocity`: Velocidad inicial
- `initialDirection`: Dirección inicial
- `useSeparateAxisMovement`: Usar movimiento por ejes
- `velocityX_min/max`: Rango de velocidad en X
- `velocityY_min/max`: Rango de velocidad en Y
- `windEffect`: Efecto de viento
- `turbulence`: Turbulencia aleatoria

### Propiedades visuales
- `scale_min/max`: Escala (tamaño)
- `useScaleVec`: Usar escala vectorial
- `scaleX_min/max`: Escala en X
- `scaleY_min/max`: Escala en Y
- `initialAlpha`: Transparencia inicial
- `initialRotation`: Rotación inicial
- `isAdditive`: Modo de mezcla aditivo

### Animación
- `fadeOutAtEnd`: Desvanecer al final
- `scaleOverLifetime`: Escalar durante su vida
- `rotateOverLifetime`: Rotar durante su vida
- `useRandomEasing`: Usar easings aleatorios

## Instalación y uso

1. Los scripts se almacenan en la carpeta `scripts` dentro del directorio principal de la aplicación.
2. La aplicación proporciona plantillas predefinidas para ayudar a crear nuevos scripts.
3. Para mostrar/ocultar la interfaz de scripts, utiliza el botón de scripts en el panel de herramientas.
4. Para ejecutar un script, selecciónalo en el panel de scripts y presiona "Ejecutar".
5. Para editar los parámetros, utiliza los campos en el panel de parámetros.

## Plantillas disponibles

El sistema incluye plantillas para los siguientes efectos:

- **Lluvia**: Efecto de gotas de lluvia cayendo.
- **Fuego**: Efecto de llamas ascendentes.

---

## Ejemplo: Crear un efecto de nieve personalizado

```javascript
var params = {
    startTime: 0,
    endTime: 15000,
    intensity: 40,
    windEffect: 15,
    fallSpeed: 50
};

function main() {
    // Obtener tiempo actual si es necesario
    if (params.startTime === 0) {
        params.startTime = ParticleAPI.getCurrentTime();
        params.endTime = params.startTime + 15000;
    }
    
    var settings = {
        texture: "SB/Effects/snowflake.png",
        startTime: params.startTime,
        endTime: params.endTime,
        particleCount: params.intensity,
        emissionMode: "continuous",
        
        // Línea horizontal en la parte superior
        emissionShape: "line",
        startX: -127,
        startY: -20,
        endX: 720,
        endY: -20,
        
        // Propiedades de movimiento
        useSeparateAxisMovement: true,
        velocityX_min: -40,
        velocityX_max: 40,
        velocityY_min: 30,
        velocityY_max: params.fallSpeed,
        
        windEffect: params.windEffect,
        turbulence: 15,
        
        // Tiempo de vida
        lifetime_min: 4000,
        lifetime_max: 8000,
        
        // Propiedades visuales
        initialScale: {
            min: 0.1,
            max: 0.3
        },
        initialAlpha: {
            min: 0.7,
            max: 1.0
        },
        
        // Opciones de animación
        fadeOutAtEnd: true,
        rotateOverLifetime: true,
        useRandomEasing: true
    };
    
    ParticleAPI.createParticleEffect("SnowEffect", settings);
    
    ParticleAPI.defineParameters("SnowEffect", params);
}

function getParameters() {
    return params;
}

function updateParameter(name, value) {
    params[name] = value;
}
```
