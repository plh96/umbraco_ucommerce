/*
	Fix for images being rendered as text boxes
*/
		
UPDATE uCommerce_DataType SET DefinitionName = 'Media' WHERE TypeName = 'Image'