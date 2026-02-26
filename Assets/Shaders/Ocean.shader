Shader "Ocean"
{
    Properties
    {
        //Alpha Blend by default
        [Enum(UnityEngine.Rendering.BlendMode)] _Src("Blend Src", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _Dst("Blend Dst", Float) = 10

        //Textures, tiling and layers speed
        [NoScaleOffset]_WavesTex ("Texture", 2D) = "white" {}
        [NoScaleOffset]_MaskTex ("Texture2", 2D) = "white" {}
        _Speed_0 ("Speed 0", Float) = 6.0
        _Speed_1 ("Speed 1", Float) = 6.0
        _Tiling_0("Tiling 0", Vector) = (1,1,0,0)
        _UV_Angle ("Waves Angle", Range(0, 360)) = 0
        
        //Colors of water
        _ColorA ("Color A", Color) = (0.0, 0.5, 0.8, 1)
        _ColorB ("Color B", Color) = (0.35, 0.9, 0.55, 1)
        _ColorH ("Color H", Color) = (0.376, 0.894, 0.901, 1.0)
        
        //Mesh wobble 
        _PositionScale("Position Scale", Float) = 0.1
        _SpeedX("Speed X", Float) = 1.0
        _SpeedY("Speed Y", Float) = 1.0
        _SizeX("Size X", Float) = 1.0
        _SizeY("Size Y", Float) = 1.0
        
        //Shore line
        _EdgeMin ("Edge Min", Float) = 0.1
        _EdgeMax("Edge Max", Float) = 1.0
        _EdgeWidth("Edge Width", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        ZWrite Off
        Blend [_Src] [_Dst]
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            #define PI 3.1415926535897932384626433832795

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float3 normal : NORMAL;
                float4 color : COLOR;
            };

            struct v2f
            {
                float2 texcoord : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float2 texcoord2 : TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            sampler2D _WavesTex;
            sampler2D _MaskTex;

            float _Speed_0, _Speed_1, _Normal;
            float4 _Tiling_0;

            float4 _ColorA, _ColorB, _ColorH;
            float _PositionScale, _SpeedX, _SpeedY, _SizeX, _SizeY;
            float _EdgeMin, _EdgeMax, _EdgeWidth, _UV_Angle;

            float2 RotateUV(float2 uv, float angel)
            {
                float2 o_uv;
                angel = angel * (PI/180.0f);
                
                float s = sin(angel);
                float c = cos(angel);
                float2x2 rotationMat = float2x2(c, -s, s, c);

                o_uv = mul(uv, rotationMat);
                
                return o_uv;
            }

            v2f vert (appdata v)
            {
                v2f o;

                //Wobble effect
                float offset = (v.vertex.x + v.vertex.y + v.vertex.z) / _PositionScale + _Time.x;
                float c = _SizeX * cos(_SpeedX * offset) * v.color;
                float s = _SizeY * sin(_SpeedY * offset) * v.color;
                float4 pos = float4(v.vertex.x + c, v.vertex.y, v.vertex.z + s, v.vertex.w);

                //UVs
                float2 v_texcoord = v.texcoord * _Tiling_0.xy - _Speed_0 * _Time;
                float2 v_texcoord1 = v.texcoord * _Tiling_0.zw - _Speed_1 * _Time;
                float2 v_texcoord2 = v.texcoord;

                v_texcoord = RotateUV(v_texcoord, _UV_Angle);
                v_texcoord1 = RotateUV(v_texcoord1, _UV_Angle);

                //Positions output
                o.vertex = UnityObjectToClipPos(pos);
                
                o.texcoord = v_texcoord;
                o.texcoord1 = v_texcoord1;
                o.texcoord2 = v_texcoord2;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                fixed4 waterColor1 = tex2D(_WavesTex, i.texcoord);
                fixed4 waterColor2 = tex2D(_WavesTex, i.texcoord1);
                fixed4 color2 = tex2D(_MaskTex, i.texcoord2);

                fixed4 waterColor = waterColor1 + waterColor2;
                half foam = clamp(1.25 * (color2.g - 0.2), 0.0, 1.0);
                half opacity = color2.r - foam * 0.2;
                half light = color2.b;

                fixed4 colorNew = lerp(fixed4(_ColorA.x, _ColorA.y, _ColorA.z, opacity), waterColor1, 0.25);
                fixed4 color = lerp(fixed4(_ColorB.x, _ColorB.y, _ColorB.z, opacity), colorNew, opacity);
        
                half wSum = waterColor.r + waterColor.g + waterColor.b;
                half wFoam = wSum * (wSum - 3.2);

                wFoam = clamp(wFoam * 0.275 , 0.0, 1.0);
                
                color = lerp(color, float4(1.0, 1.0, 1.0, 1.0), wFoam); //Foam color is white
                color = lerp(color, _ColorH, light);
                
                half edge = smoothstep(_EdgeMax , _EdgeMax + _EdgeWidth,  foam*wSum );
                half edge2 = smoothstep(_EdgeMin , _EdgeMin + _EdgeWidth,  foam);
                half shoreEdge = edge * (1- edge2);
                
                color.a *= 1 - edge;
                color += saturate(shoreEdge);
                
                return color;
            }
            ENDCG
        }
    }
}