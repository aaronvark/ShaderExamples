using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SetShaderValue : MonoBehaviour {

    public enum ValueType {
        POSITION
    }

    public string name = "_ShaderVar";
    public ValueType value;
	// Update is called once per frame
	void Update () {
        switch(value) {
            case ValueType.POSITION:
                Shader.SetGlobalVector(name, transform.position);
                break;
        }
	}
}
