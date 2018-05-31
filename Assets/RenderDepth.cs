using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RenderDepth : MonoBehaviour {
	public Shader depthShader;
	public Camera targetCamera;
	public string renderTargetName = "_CustomDepth";

	RenderTexture rt;

	private void Start() {
		GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;

		//rt = new RenderTexture(Screen.width, Screen.height, 0);
		//rt.Create();

		//targetCamera.targetTexture = rt;
	}

	void OnPreRender() {
		//rt = RenderTexture.GetTemporary(Screen.width, Screen.height);
		
		//targetCamera.RenderWithShader(depthShader, "");
		//Shader.SetGlobalTexture("_CustomDepth", rt);

		//RenderTexture.ReleaseTemporary(rt);
	}
}
