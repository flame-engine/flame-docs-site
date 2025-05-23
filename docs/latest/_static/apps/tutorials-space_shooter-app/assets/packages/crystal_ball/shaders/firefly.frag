{
  "sksl": {
    "entrypoint": "firefly_fragment_main",
    "shader": "// This SkSL shader is autogenerated by spirv-cross.\n\nfloat4 flutter_FragCoord;\n\nuniform vec2 uSize;\nuniform float uGroundPos;\nuniform float uGroundAdd;\nuniform float uFade;\nuniform float uTime;\n\nvec4 fragColor;\n\nvec2 FLT_flutter_local_FlutterFragCoord()\n{\n    return flutter_FragCoord.xy;\n}\n\nfloat FLT_flutter_local_random(vec2 st)\n{\n    return fract(sin(dot(st, vec2(12.98980045318603515625, 78.233001708984375))) * 43758.546875);\n}\n\nvec4 FLT_flutter_local_circle(vec2 uv, vec2 center, float radius)\n{\n    vec2 pos = center - uv;\n    pos.y /= (uSize.x / uSize.y);\n    float dist = 1.0 / length(pos);\n    dist *= radius;\n    dist = (dist * 0.89999997615814208984375) / 2.0;\n    float ddist = pow(dist, 1.10000002384185791015625);\n    vec3 col = vec3(0.300000011920928955078125, 0.89999997615814208984375, 0.20000000298023223876953125) * ddist;\n    col = vec3(1.0) - exp(-col);\n    return vec4(col, pow(ddist * 0.00999999977648258209228515625, 3.0));\n}\n\nvoid FLT_flutter_local_fragment(vec2 cuv, vec2 pos, inout vec4 color)\n{\n    vec2 p = pos / uSize;\n    vec2 uv = p * vec2(uSize.x / uSize.y, 1.0);\n    float waterline = uGroundPos;\n    float fade = 9.19999980926513671875;\n    float tr = step(waterline - fade, uv.y);\n    tr *= smoothstep(waterline - fade, waterline, uv.y);\n    uv.y -= 0.20000000298023223876953125;\n    uv.y -= (uGroundAdd * 0.4000000059604644775390625);\n    vec2 aspect = vec2(uSize.x / uSize.y, 1.0);\n    color = vec4(0.0);\n    for (int i = 0; i < 10; i++)\n    {\n        float t = (float(i) * 0.5) + (uTime * 0.20000000298023223876953125);\n        vec2 param = vec2(float(i), 1.2339999675750732421875);\n        vec2 param_1 = vec2(float(i), 5.677999973297119140625);\n        vec2 base = vec2(FLT_flutter_local_random(param) * aspect.x, FLT_flutter_local_random(param_1) * 0.5);\n        vec2 pos_1 = base + vec2(sin(uTime + float(i)) * 0.0199999995529651641845703125, cos((uTime * 0.699999988079071044921875) + float(i)) * 0.0199999995529651641845703125);\n        vec2 param_2 = vec2(float(i), 9.01200008392333984375);\n        float size = 0.001000000047497451305389404296875 + (FLT_flutter_local_random(param_2) * 0.004999999888241291046142578125);\n        vec2 param_3 = uv;\n        vec2 param_4 = pos_1;\n        float param_5 = size * 3.0;\n        vec4 firefly = FLT_flutter_local_circle(param_3, param_4, param_5);\n        color += firefly;\n    }\n    float f = 1.0;\n    f *= tr;\n    f *= 0.64999997615814208984375;\n    vec4 _259 = color;\n    vec3 _261 = _259.xyz * f;\n    color.x = _261.x;\n    color.y = _261.y;\n    color.z = _261.z;\n}\n\nvoid FLT_main()\n{\n    vec2 pos_2 = FLT_flutter_local_FlutterFragCoord();\n    vec2 uv_1 = pos_2 / uSize;\n    vec2 param_6 = uv_1;\n    vec2 param_7 = pos_2;\n    vec4 color_1;\n    vec4 param_8 = color_1;\n    FLT_flutter_local_fragment(param_6, param_7, param_8);\n    color_1 = param_8;\n    fragColor = color_1;\n}\n\nhalf4 main(float2 iFragCoord)\n{\n      flutter_FragCoord = float4(iFragCoord, 0, 0);\n      FLT_main();\n      return fragColor;\n}\n",
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
        "name": "uGroundPos",
        "rows": 1,
        "type": 10
      },
      {
        "array_elements": 0,
        "bit_width": 32,
        "columns": 1,
        "location": 2,
        "name": "uGroundAdd",
        "rows": 1,
        "type": 10
      },
      {
        "array_elements": 0,
        "bit_width": 32,
        "columns": 1,
        "location": 3,
        "name": "uFade",
        "rows": 1,
        "type": 10
      },
      {
        "array_elements": 0,
        "bit_width": 32,
        "columns": 1,
        "location": 4,
        "name": "uTime",
        "rows": 1,
        "type": 10
      }
    ]
  }
}