IntToHexa(_entier, _size=4, _prefix=true)
{
	; _entier must be an integer positive or negative
	; _size is the number of Hexa digits (1, 2, 3, 4, etc.)
	local Hexa, LimitInf, LimitSup
		
	if _entier is not Integer
		return

	if _size is not Integer
		return

	if (_size < 1 or _size > 15)
		return
	
	if (_prefix <> true and _prefix <> false)
		return

	LimitSup := 16 ** _size
   
	oldFormat := A_FormatInteger 
	SetFormat IntegerFast, H

	if (_entier < 0)
	{
		Hexa := _entier + LimitSup
		
		if (_prefix = false)
			Hexa := SubStr(Hexa, 3)
	}
	else
	{
		Hexa := SubStr(_entier + 0, 3)
		
		LimitInf := 1
		while (LimitInf *= 16) < LimitSup
			if (_entier < LimitInf)
				Hexa := "0" Hexa
		
		if _prefix
			Hexa := "0x" Hexa
	}
		
	SetFormat IntegerFast, %oldFormat%
	return Hexa
}
