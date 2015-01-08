# # Utils
#
# ### Exports: *Object*
# 
# A collection of helper functions

# export the functions
module.exports = 
	###
	## randomString
	
	`utils.randomString( string_length, speciallevel )`
	
	Generate a random string
	
	@param { Number } string_length string length to generate 
	@param { Number } speciallevel Level of complexity.
		* 0 = only letters upper and lowercase, 52 possible chars;
		* 1 = 0 + Numbers, 62 possible chars;
		* 2 = 1 + "_-@:.", 67 possible chars;
		* 3 = 2 + may speacial chars, 135 possible chars;
	
	@return { String } The gerated string 
	###
	randomString: ( string_length = 5, specialLevel = 0 ) ->
		chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
		chars += "0123456789" if specialLevel >= 1
		chars += "_-@:." if specialLevel >= 2
		chars += "!\"§$%&/()=?*'_:;,.-#+¬”#£ﬁ^\\˜·¯˙˚«∑€®†Ω¨⁄øπ•‘æœ@∆ºª©ƒ∂‚å–…∞µ~∫√ç≈¥" if specialLevel >= 3

		randomstring = ""
		i = 0
		
		while i < string_length
			rnum = Math.floor(Math.random() * chars.length)
			randomstring += chars.substring(rnum, rnum + 1)
			i++
		randomstring

	###
	## randRange
	
	`utils.randRange( lowVal, highVal )`
	
	Create a random number bewtween two values
	
	@param { Number } lowVal Min number 
	@param { Number } highVal Max number 
	
	@return { Number } A random number 
	###
	randRange: ( lowVal, highVal )->
		return Math.floor( Math.random()*(highVal-lowVal+1 ))+lowVal

	###
	## randRange
	
	`utils.randRange( lowVal, highVal )`
	
	Create a random number bewtween two values
	
	@param { Number|String } value The value to pad
	@param { Number } [padding=2] The padding size
	@param { String } [fill="0"] The filler value.
	
	@return { String } the padded value
	###
	lpad: (value, padding = 2, fill = "0") ->
		fill += fill for i in [1..padding]
		return (fill + value).slice(padding * -1)