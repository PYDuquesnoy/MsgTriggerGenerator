# MsgTriggerGenerator
Trigger Generator for InterSystems IRIS Messages, to Delete References Persistent Classes on Message Purge

The Intersystems IRIS Interoperability messages are automatically saved in the IRIS Database. A Nightly purge takes care of deleting old messages once the defined retention period has passed.
The Purge Utility deletes all messages referenced by the MessageHeader. However, when a messages reuses other persistent classes (as properties or collections of type List/Array/RelationShip), these referenced entities are not deleted autmatically by the Purge Utility, as they are separate persistent entities.
Current possible solutions to this problem are:
* use %SerialObjects for the additional classes referenced by a message. This way, the serial entities get stored and deleted as part of the MessageBody
* manually define a Delete Trigger as part of the message definition to delete the related entities when the messagebody gets deleted
    * The WSDL Import Wizard already offers this "Automatic Trigger Definition" as an option when defining persistent clases for SOAP Request and Response entities.   

This project defines an additional SuperClass that can be added when defining message classes. It automatically generates the correct trigger as part of the message class compilation. The Added Delete trigger (visible only in the generated .INT code of the subclass) loops over all properties of the messagebody which reference persistent clases and deletes this referenced instances as well. It handle both single value properties as well as List and Array Collections, including One to Many or Parent-childen RelationShips.

Usage

In your message Class, just add the  an additional superclass like this:
Class Alt.Msg.Test Extends (Ens.Request, Msg.Super) { ... }
