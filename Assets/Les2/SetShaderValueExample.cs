using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SetShaderValueExample : MonoBehaviour {

	public Material m;
	public string name = "_Alpha";

	// Update is called once per frame
	void Update () {
		//m.SetFloat(name, Mathf.Abs(Mathf.Sin(Time.time)));
		Shader.SetGlobalFloat(name, Mathf.Abs(Mathf.Sin(Time.time)));
	}
}
