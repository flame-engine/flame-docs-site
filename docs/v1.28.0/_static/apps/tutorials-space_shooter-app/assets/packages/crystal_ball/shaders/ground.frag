{
  "sksl": {
    "entrypoint": "ground_fragment_main",
    "shader": "// This SkSL shader is autogenerated by spirv-cross.\n\nfloat4 flutter_FragCoord;\n\nuniform vec2 uSize;\nuniform float uPixelSize;\nuniform float uWaterLevel;\nuniform float uTime;\nuniform shader tGameCanvas;\nuniform half2 tGameCanvas_size;\n\nvec4 fragColor;\n\nvec2 FLT_flutter_local_FlutterFragCoord()\n{\n    return flutter_FragCoord.xy;\n}\n\nvec4 FLT_flutter_local_fragment(vec2 uv)\n{\n    vec4 waterColor = vec4(1.0);\n    vec2 reflectedUv = uv;\n    float fogIntensity = 0.0;\n    vec4 fogColor = vec4(1.0, 0.60000002384185791015625, 1.0, 0.20000000298023223876953125);\n    if (uv.y >= uWaterLevel)\n    {\n        reflectedUv.y = (2.0 * uWaterLevel) - reflectedUv.y;\n        float distFromWater = reflectedUv.y - uWaterLevel;\n        float angleFactr = 2.1217749118804931640625;\n        float magnification = 2.0 + distFromWater;\n        reflectedUv.y = uWaterLevel + (distFromWater * magnification);\n        reflectedUv.x += (sin((uv.y - (uWaterLevel / 1.0)) + (uTime * 1.0)) * 0.00999999977648258209228515625);\n        reflectedUv.y += (cos((1.0 / (uv.y - uWaterLevel)) + (uTime * 1.0)) * 0.02999999932944774627685546875);\n        if (reflectedUv.y <= 0.0)\n        {\n            return vec4(0.0);\n        }\n        waterColor = vec4(1.0);\n        vec4 _120 = waterColor;\n        vec3 _122 = _120.xyz * (1.0 - ((uv.y - uWaterLevel) / (1.0 - uWaterLevel)));\n        waterColor.x = _122.x;\n        waterColor.y = _122.y;\n        waterColor.z = _122.z;\n        float waterProximity = 1.0 - min(1.0, (uv.y - uWaterLevel) * 23.0);\n        fogIntensity = waterProximity * 0.100000001490116119384765625;\n    }\n    else\n    {\n        float waterProximity_1 = 1.0 - min(1.0, (uWaterLevel - uv.y) * 5.0);\n        fogIntensity = waterProximity_1 * 0.100000001490116119384765625;\n    }\n    vec4 baseColor = tGameCanvas.eval(tGameCanvas_size * ( reflectedUv / vec2(uPixelSize))) * waterColor;\n    return mix(baseColor, fogColor, vec4(fogIntensity));\n}\n\nvoid FLT_main()\n{\n    vec2 pos = FLT_flutter_local_FlutterFragCoord();\n    vec2 uv_1 = pos / uSize;\n    vec2 param = uv_1;\n    fragColor = FLT_flutter_local_fragment(param);\n}\n\nhalf4 main(float2 iFragCoord)\n{\n      flutter_FragCoord = float4(iFragCoord, 0, 0);\n      FLT_main();\n      return fragColor;\n}\n",
    "stage": 1,
    "uniforms": [
      {
        "array_elements": 0,
        "bit_width": 32,
        "columns": 1,
        "location": 0,
        "name": "uSize",
        "rows": 2,
        "type": 10
      },
      {
        "array_elements": 0,
        "bit_width": 32,
        "columns": 1,
        "location": 1,
        "name": "uPixelSize",
        "rows": 1,
        "type": 10
      },
      {
        "array_elements": 0,
        "bit_width": 32,
        "columns": 1,
        "location": 2,
        "name": "uWaterLevel",
        "rows": 1,
        "type": 10
      },
      {
        "array_elements": 0,
        "bit_width": 32,
        "columns": 1,
        "location": 3,
        "name": "uTime",
        "rows": 1,
        "type": 10
      },
      {
        "array_elements": 0,
        "bit_width": 0,
        "columns": 1,
        "location": 4,
        "name": "tGameCanvas",
        "rows": 1,
        "type": 12
      }
    ]
  }
}