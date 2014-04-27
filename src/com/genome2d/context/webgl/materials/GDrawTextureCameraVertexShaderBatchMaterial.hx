package com.genome2d.context.webgl.materials;

import js.html.Uint16Array;
import js.html.webgl.Texture;
import js.html.webgl.Shader;
import js.html.webgl.Program;
import js.html.webgl.Buffer;
import js.html.webgl.RenderingContext;
import js.html.webgl.UniformLocation;
import com.genome2d.textures.GContextTexture;
import com.genome2d.textures.GTexture;
import js.html.Float32Array;

class GDrawTextureCameraVertexShaderBatchMaterial
{
    inline static private var BATCH_SIZE:Int = 10;

    inline static private var TRANSFORM_PER_VERTEX:Int = 3;
    inline static private var TRANSFORM_PER_VERTEX_ALPHA:Int = TRANSFORM_PER_VERTEX+1;

    private var g2d_nativeContext:RenderingContext;
	private var g2d_quadCount:Int = 0;
	
	private var g2d_geometryBuffer:Buffer;
    private var g2d_uvBuffer:Buffer;
    private var g2d_shaderIndexBuffer:Buffer;

    private var g2d_indexBuffer:Buffer;

    private var g2d_activeNativeTexture:Texture;

    private var g2d_transforms:Float32Array;

	inline static private var VERTEX_SHADER_CODE:String = 
         "
			uniform mat4 projectionMatrix;
			uniform vec4 transforms[50];

			attribute vec2 aPosition;
			attribute vec2 aTexCoord;
			attribute vec3 aShaderIndex;

			varying vec2 vTexCoord;

			void main(void)
			{
				gl_Position = vec4(aPosition.x*transforms[int(aShaderIndex.x)].z, aPosition.y*transforms[int(aShaderIndex.x)].w, 0, 1);
				gl_Position = vec4(gl_Position.x+transforms[int(aShaderIndex.x)].x, gl_Position.y+transforms[int(aShaderIndex.x)].y, 0, 1);
				gl_Position = gl_Position * projectionMatrix;

				vTexCoord = vec2(aTexCoord.x*transforms[int(aShaderIndex.y)].z+transforms[int(aShaderIndex.y)].x, aTexCoord.y*transforms[int(aShaderIndex.y)].w+transforms[int(aShaderIndex.y)].y);
			}
		 ";

	inline static private var FRAGMENT_SHADER_CODE:String =
        "
			#ifdef GL_ES
			precision highp float;
			#endif

			varying vec2 vTexCoord;

			uniform sampler2D sTexture;

			void main(void)
			{
				vec4 texColor;
				texColor = texture2D(sTexture, vTexCoord);
				gl_FragColor = texColor;
			}
		";

	public var g2d_program:Dynamic;
	
	public function new():Void {
    }

    private function getShader(shaderSrc:String, shaderType:Int):Shader {
        var shader:Shader = g2d_nativeContext.createShader(shaderType);
        g2d_nativeContext.shaderSource(shader, shaderSrc);
        g2d_nativeContext.compileShader(shader);

        /* Check for erros
        if (!g2d_nativeContext.getShaderParameter(shader, RenderingContext.COMPILE_STATUS)) {
            trace("Shader compilation error: " + g2d_nativeContext.getShaderInfoLog(shader)); return null;
        }
        /**/
        return shader;
    }

    public function initialize(p_context:RenderingContext):Void {
		g2d_nativeContext = p_context;
		
		var fragmentShader = getShader(FRAGMENT_SHADER_CODE, RenderingContext.FRAGMENT_SHADER);
		var vertexShader = getShader(VERTEX_SHADER_CODE, RenderingContext.VERTEX_SHADER);

		g2d_program = g2d_nativeContext.createProgram();
		g2d_nativeContext.attachShader(g2d_program, vertexShader);
		g2d_nativeContext.attachShader(g2d_program, fragmentShader);
		g2d_nativeContext.linkProgram(g2d_program);

		//if (!RenderingContext.getProgramParameter(program, RenderingContext.LINK_STATUS)) { trace("Could not initialise shaders"); }

		g2d_nativeContext.useProgram(g2d_program);

        var vertices:Float32Array = new Float32Array(8*BATCH_SIZE);
        var uvs:Float32Array = new Float32Array(8*BATCH_SIZE);
        var registerIndices:Float32Array = new Float32Array(TRANSFORM_PER_VERTEX*BATCH_SIZE*4);
        //var registerIndicesAlpha:Float32Array = new Float32Array();

        for (i in 0...BATCH_SIZE) {
            vertices[i*8] = GMaterialCommon.NORMALIZED_VERTICES[0];
            vertices[i*8+1] = GMaterialCommon.NORMALIZED_VERTICES[1];
            vertices[i*8+2] = GMaterialCommon.NORMALIZED_VERTICES[2];
            vertices[i*8+3] = GMaterialCommon.NORMALIZED_VERTICES[3];
            vertices[i*8+4] = GMaterialCommon.NORMALIZED_VERTICES[4];
            vertices[i*8+5] = GMaterialCommon.NORMALIZED_VERTICES[5];
            vertices[i*8+6] = GMaterialCommon.NORMALIZED_VERTICES[6];
            vertices[i*8+7] = GMaterialCommon.NORMALIZED_VERTICES[7];

            uvs[i*8] = GMaterialCommon.NORMALIZED_UVS[0];
            uvs[i*8+1] = GMaterialCommon.NORMALIZED_UVS[1];
            uvs[i*8+2] = GMaterialCommon.NORMALIZED_UVS[2];
            uvs[i*8+3] = GMaterialCommon.NORMALIZED_UVS[3];
            uvs[i*8+4] = GMaterialCommon.NORMALIZED_UVS[4];
            uvs[i*8+5] = GMaterialCommon.NORMALIZED_UVS[5];
            uvs[i*8+6] = GMaterialCommon.NORMALIZED_UVS[6];
            uvs[i*8+7] = GMaterialCommon.NORMALIZED_UVS[7];

            var index:Int = (i * TRANSFORM_PER_VERTEX);
            var array:Array<Float> = [index, index + 1, index + 2, index, index + 1, index + 2, index, index + 1, index + 2,  index, index + 1, index + 2];
            registerIndices[i*TRANSFORM_PER_VERTEX*4] = index;
            registerIndices[i*TRANSFORM_PER_VERTEX*4+1] = index+1;
            registerIndices[i*TRANSFORM_PER_VERTEX*4+2] = index+2;
            registerIndices[i*TRANSFORM_PER_VERTEX*4+3] = index;
            registerIndices[i*TRANSFORM_PER_VERTEX*4+4] = index+1;
            registerIndices[i*TRANSFORM_PER_VERTEX*4+5] = index+2;
            registerIndices[i*TRANSFORM_PER_VERTEX*4+6] = index;
            registerIndices[i*TRANSFORM_PER_VERTEX*4+7] = index+1;
            registerIndices[i*TRANSFORM_PER_VERTEX*4+8] = index+2;
            registerIndices[i*TRANSFORM_PER_VERTEX*4+9] = index;
            registerIndices[i*TRANSFORM_PER_VERTEX*4+10] = index+1;
            registerIndices[i*TRANSFORM_PER_VERTEX*4+11] = index+2;
        }

        g2d_geometryBuffer = g2d_nativeContext.createBuffer();
        g2d_nativeContext.bindBuffer(RenderingContext.ARRAY_BUFFER, g2d_geometryBuffer);
        g2d_nativeContext.bufferData(RenderingContext.ARRAY_BUFFER, vertices, RenderingContext.STREAM_DRAW);

        g2d_uvBuffer = g2d_nativeContext.createBuffer();
        g2d_nativeContext.bindBuffer(RenderingContext.ARRAY_BUFFER, g2d_uvBuffer);
        g2d_nativeContext.bufferData(RenderingContext.ARRAY_BUFFER, uvs, RenderingContext.STREAM_DRAW);

        g2d_shaderIndexBuffer = g2d_nativeContext.createBuffer();
        g2d_nativeContext.bindBuffer(RenderingContext.ARRAY_BUFFER, g2d_shaderIndexBuffer);
        g2d_nativeContext.bufferData(RenderingContext.ARRAY_BUFFER, registerIndices, RenderingContext.STREAM_DRAW);

        var indices:Uint16Array = new Uint16Array(BATCH_SIZE * 6);
        for (i in 0...BATCH_SIZE) {
            var ao:Int = i*6;
            var io:Int = i*4;
            indices[ao] = io;
            indices[ao+1] = io+1;
            indices[ao+2] = io+2;
            indices[ao+3] = io;
            indices[ao+4] = io+2;
            indices[ao+5] = io+3;
        }

        g2d_indexBuffer = g2d_nativeContext.createBuffer();
        g2d_nativeContext.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, g2d_indexBuffer);
        g2d_nativeContext.bufferData(RenderingContext.ELEMENT_ARRAY_BUFFER, indices, RenderingContext.STATIC_DRAW);

		g2d_program.samplerUniform = g2d_nativeContext.getUniformLocation(g2d_program, "sTexture");

        g2d_program.positionAttribute = g2d_nativeContext.getAttribLocation(g2d_program, "aPosition");
        g2d_nativeContext.enableVertexAttribArray(g2d_program.positionAttribute);

        g2d_program.texCoordAttribute = g2d_nativeContext.getAttribLocation(g2d_program, "aTexCoord");
        g2d_nativeContext.enableVertexAttribArray(g2d_program.texCoordAttribute);

        g2d_program.shaderIndexAttribute = g2d_nativeContext.getAttribLocation(g2d_program, "aShaderIndex");
        g2d_nativeContext.enableVertexAttribArray(g2d_program.shaderIndexAttribute);

        g2d_transforms = new Float32Array(50*4);
	}

    public function bind(p_projection:Float32Array):Void {
        g2d_nativeContext.uniformMatrix4fv(g2d_nativeContext.getUniformLocation(g2d_program, "projectionMatrix"), false,  p_projection);

        g2d_nativeContext.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, g2d_indexBuffer);

        g2d_nativeContext.bindBuffer(RenderingContext.ARRAY_BUFFER, g2d_geometryBuffer);
        g2d_nativeContext.vertexAttribPointer(g2d_program.positionAttribute, 2, RenderingContext.FLOAT, false, 0, 0);

        g2d_nativeContext.bindBuffer(RenderingContext.ARRAY_BUFFER, g2d_uvBuffer);
        g2d_nativeContext.vertexAttribPointer(g2d_program.texCoordAttribute, 2, RenderingContext.FLOAT, false, 0, 0);

        g2d_nativeContext.bindBuffer(RenderingContext.ARRAY_BUFFER, g2d_shaderIndexBuffer);
        g2d_nativeContext.vertexAttribPointer(g2d_program.shaderIndexdAttribute, 3, RenderingContext.FLOAT, false, 0, 0);
    }
	
	public function draw(p_x:Float, p_y:Float, p_scaleX:Float, p_scaleY:Float, p_rotation:Float, p_texture:GContextTexture):Void {
        var notSameTexture:Bool = g2d_activeNativeTexture != p_texture.nativeTexture;

        if (notSameTexture) {
            if (g2d_activeNativeTexture != null) push();

            if (notSameTexture) {
                g2d_activeNativeTexture = p_texture.nativeTexture;
                g2d_nativeContext.activeTexture(RenderingContext.TEXTURE0);
                g2d_nativeContext.bindTexture(RenderingContext.TEXTURE_2D, p_texture.nativeTexture);
                untyped g2d_nativeContext.uniform1i(g2d_program.samplerUniform, 0);
            }
        }

        g2d_program.shaderIndexAttribute = g2d_nativeContext.getUniformLocation(g2d_program, "aShaderIndex");

        var offset:Int = g2d_quadCount*12;
        g2d_transforms[offset] = p_x;
        g2d_transforms[offset+1] = p_y;
        g2d_transforms[offset+2] = p_scaleX*p_texture.width;
        g2d_transforms[offset+3] = p_scaleY*p_texture.height;

        g2d_transforms[offset+4] = p_texture.uvX;
        g2d_transforms[offset+5] = p_texture.uvY;
        g2d_transforms[offset+6] = p_texture.uvScaleX;
        g2d_transforms[offset+7] = p_texture.uvScaleY;

		g2d_quadCount++;

        if (g2d_quadCount == BATCH_SIZE) push();
	}
	
	public function push():Void {
        g2d_nativeContext.uniform4fv(g2d_nativeContext.getUniformLocation(g2d_program, "transforms"), g2d_transforms);

        g2d_nativeContext.drawElements(RenderingContext.TRIANGLES, 6*g2d_quadCount, RenderingContext.UNSIGNED_SHORT, 0);

        g2d_quadCount = 0;
    }

    public function clear():Void {
        g2d_activeNativeTexture = null;
    }
}