using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomImageEffect : MonoBehaviour {

	public Material mat;

	private void Start() {
		MyInt x = 1;
		int y = x;
		bool? b = x;
	}

	void OnRenderImage(RenderTexture src, RenderTexture dest) {
		Graphics.Blit(src, dest, mat);
	}
}