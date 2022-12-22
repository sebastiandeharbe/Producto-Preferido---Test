codeunit 50200 "TestProductoPreferido"
{
    Subtype = Test;

    trigger OnRun()
    begin

    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";

    [Test]
    procedure CrearRandomItems()
    // [FEATURE] Feature Id / Description
    // [SCENARIO] Scenario Description
    var
        i: Integer;
        recitem: Record Item;
    begin
        // [GIVEN] Given
        //none
        // [WHEN] When
        for i := 0 to 10 do begin
            CreateRandomItem(recitem);
        end;
        // [THEN] Then. Se crean 10 productos.

    end;

    //TEST QUE NO ESPERA UN ERROR
    [Test]
    [HandlerFunctions('HandleMessageOnValidateProductoPreferido,ExpectedConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestCheckValidateProductoPreferido()
    var
        RecItem: Record Item;
        RecCustomer: Record Customer;
    begin
        //[Scenario] 
        //Creo un cliente y le asigno un producto preferido que se crea aleatoriamente.
        //El test debe pasar sin errores. 

        //[Given]
        CreateRandomItem(RecItem);
        LibrarySales.CreateCustomer(RecCustomer); //La libreria lo crea automáticamente.

        //[When]
        RecCustomer.Validate("Producto Preferido", RecItem."No.");

        //[Then]
        //No se debe producir error
    end;

    //TEST PARA PROBAR EL EXCESO DE CARACTERES EN UN CAMPO
    [Test]
    procedure TestFailFieldProductoPreferido()
    var
        RecCustomer: Record Customer;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryError: Codeunit "Library - Error Message";
        ExpectedError: Label 'StringLengthExceeded';
        ActualError: Text;
    begin
        // [Scenario] 
        //The user ingresa 200 caracteres, de alguna forma, en el campo de Producto Preferido
        // [Given] Setup: 
        LibrarySales.CreateCustomer(RecCustomer);

        // [When] Exercise: 
        asserterror RecCustomer."Producto Preferido" := LibraryUtility.GenerateRandomText(200);

        // [Then] Verify: 
        ActualError := GetLastErrorCode();
        Assert.AreEqual(ExpectedError, ActualError, 'No es el error esperado. ');
    end;

    //TEST QUE ESPERA UN ERROR
    [Test]
    [Scope('OnPrem')]
    procedure TestFailValidateProductoPreferido()
    var
        RecCustomer: Record Customer;
        ErrorExp: label 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).';
        RecItem: Record Item;
    begin
        //[Escenario] - [Escenario] -> Descripción de lo que realiza el test
        //Comprobar que el item No. existe. El Test pasa si se obtiene el mensaje de error esperado.
        //Comprueba el TableRelation del campo Producto Preferido

        //[Condiciones] - [Given] -> Condiciones que existen en bc antes de la acción
        //Crear un cliente sin producto preferido
        LibrarySales.CreateCustomer(RecCustomer); //La libreria lo crea automáticamente. 

        //[Acción del usuario] - [When] -> Acción del usuario
        asserterror RecCustomer.Validate("Producto Preferido", 'AAAAA'); //Asigno un producto que no exite.

        //[Documentación de lo que debe pasar] - [Then] -> Lo que debe pasar
        Assert.AreEqual(StrSubstNo(ErrorExp, RecCustomer.FieldCaption("Producto Preferido"), RecCustomer.TableCaption(), 'AAAAA', RecItem.TableCaption()),
                        GetLastErrorText(),
                        'Mensaje de error incorrecto'); //Hay que asegurar que sea el error esperado. 
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldPageCustomer()
    var
        CustomerCard: TestPage "Customer Card";
        RecItem: Record Item;
        ErrorEsperado: Label 'Validation error for Field: Producto Preferido,  Message = ''The field Producto Preferido of table Customer contains a value (123) that cannot be found in the related table (Item). (Select Refresh to discard errors)''';
        ErrorActual: Text;
    begin
        //[Scenario]
        //El cliente abre la ficha de cliente para editarla y asigna el Producto Preferido '123' que no existe.
        //BC debe informar que existe un error

        //[Given]
        //Aseguro que el producto no existe en la base de datos de testing
        RecItem.Reset();
        RecItem.SetRange("No.", '123');
        If RecItem.FindFirst() then
            RecItem.Delete();

        //[When]
        CustomerCard.OpenEdit();
        asserterror CustomerCard."Producto Preferido".Value := '123';

        //[Then]
        //Debe dar error en la validación del campo. 
        ErrorActual := GetLastErrorText();
        Assert.AreEqual(ErrorEsperado, ErrorActual, 'Debería dar error de validación.');
    end;

    //TESTS EN UNA PAGE
    [Test]
    [Scope('OnPrem')]
    procedure TestPageCustomer()
    var
        CustomerCard: TestPage "Customer Card";
    begin
        //[Scenario]
        //Comprobar que existe el campo Producto Preferido en la ficha del cliente y que es editable
        //[Given]
        //No hay condiciones.
        //[When]
        //El usuario abre la ficha de un cliente.
        CustomerCard.OpenEdit(); //Abre la page en modo edit

        //[Then] 
        //El campo Producto Preferido existe y es editable
        Assert.IsTrue(CustomerCard."Producto Preferido".Visible(), 'El Campo no es visible.');
        Assert.IsTrue(CustomerCard."Producto Preferido".Editable(), 'El Campo no es editable.');
    end;

    [ConfirmHandler]
    procedure ExpectedConfirmHandlerTrue(ActualQuestion: Text[1024]; var Reply: Boolean)
    var
        ExpectedQuestion: label '¿Desea confirmar el Nuevo Producto Preferido?';
    begin
        Assert.ExpectedConfirm(ExpectedQuestion, ActualQuestion);
        Reply := true;
    end;


    //HANDLER FUNCTIONS PARA GESTIONAR MESSAGES, CONFIRMS, ETC
    [MessageHandler]
    procedure HandleMessageOnValidateProductoPreferido(Message: Text[1024])
    var
        Expected: Label 'Se añadió un Producto Preferido';
    begin
        Assert.AreEqual(Expected, Message, 'El mensaje es incorrecto.');
    end;



    //UNA FUNCIÓN AUXILIAR PARA CREAR UN PRODUCTO ALEATORIO
    local procedure CreateRandomItem(var RecItem: Record Item)
    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountry: codeunit "Library - ERM Country Data";
        RecUnitOfMeasure: Record "Unit of Measure";
    begin
        RecItem.Init();
        RecItem."No." := LibraryUtility.GenerateRandomCode20(1, 27);
        RecItem.Description := LibraryUtility.GenerateRandomText(MaxStrLen(RecItem.Description));
        RecItem.Insert();
        LibraryERMCountry.CreateUnitsOfMeasure();
        RecUnitOfMeasure.Reset();
        if RecUnitOfMeasure.FindFirst() then begin
            RecItem.Validate("Base Unit of Measure", RecUnitOfMeasure.Code);
        end;
        RecItem.Modify();
    end;
}