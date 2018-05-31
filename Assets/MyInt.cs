using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public struct MyInt {

	int intValue;

	static public implicit operator MyInt(int value) {
		MyInt retVal;
		retVal.intValue = value;
		return retVal;
	}

	static public implicit operator int(MyInt value) {
		return value.intValue;
	}

	static public implicit operator bool(MyInt value) {
		return value.intValue != 0;
	}
}