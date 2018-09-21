with GNAT.Sockets; use GNAT.Sockets;
with Types; use Types;
with Ada.Text_IO;
with Ada.Calendar;
with Ada.Calendar.Conversions;
with Ada.Streams;
with System;

procedure Connect is
   Address  : Sock_Addr_Type;
   --Server   : Socket_Type;
   Socket   : Socket_Type;
   Channel  : Stream_Access;
   
   type Payload is array (Uint_32 range <>) of Uint_8;
   
   type Payload_Rec (Len : Uint_32) is record
      Checksum : Uint_32;
      Data : Payload (1 .. Len);
   end record;

   function Mk_Payload (P : Payload) return Payload_Rec is
      Result : Payload_Rec (P'Length);
      S : String (1 .. P'Size / 8);
      for S'Address use P'Address;
      Hash : constant Uint_256 := Double_Hash (S);
   begin
      Result.Data := P;
      Result.Checksum := Uint_32_from_Hex (Large_Number_Hex (Hash) (1 .. 8));
      return Result;
   end Mk_Payload;
   
   type Command is (Version);
   
   Host_Name : constant String := "testnet-seed.bluematt.me";
   
   subtype Network_String is String (1 .. 12);

   type Port_Type is new Uint_16;
   procedure Write_Port
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : in  Port_Type);
   for Port_Type'Write use Write_Port;

   procedure Write_Port
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : in  Port_Type)
   is
      Fst : constant Uint_16 := Uint_16 (Shift_Left (Item, 8));
      Lst : constant Uint_16 := Uint_16 (Shift_Right (Item, 8));
   begin
      Uint_16'Write (Stream, Fst or Lst);
   end Write_Port;

   type Adress_Type is new String;
   for Adress_Type'Scalar_Storage_Order use System.High_Order_First;
   
   type Net_Addr is record
      Services : Uint_64;
      IPv6 : Adress_Type (1 .. 16);
      Port : Port_Type;
   end record;
   
   function Mk_Addr return Net_Addr is
   begin
      return (Services => 1, Ipv6 => "0000000000000000", Port => 18333);
   end Mk_Addr;
   
   function Command_To_String (C : Command) return Network_String is
      Result : Network_String := (others => ASCII.Nul);
      Str : constant String := (case C is when Version => "version");
   begin
      Result (1 .. Str'Length) := Str;
      return Result;
   end;

   procedure Send_Msg (C : Command; P : Payload) is
   begin
      Uint_32'Write (Channel, 16#0709110b#);
      String'Write (Channel, Command_To_String (C));
      Payload_Rec'Output (Channel, Mk_Payload (P));
   end Send_Msg;
   
   procedure Rec_Msg is
      Magic : Uint_32;
      Str : Network_String;
   begin
      Uint_32'Read (Channel, Magic);
      Network_String'Read (Channel, Str);
      Ada.Text_IO.Put_Line ("magic: " & Magic'Img);
      Ada.Text_IO.Put_Line ("command: " & Str);
      declare
         P : Payload := Payload'Input (Channel);
         pragma Unreferenced (P);
      begin
         null;
      end;
   end Rec_Msg;

   type Version_Data is record
      Version : Int_32;
      Services : Uint_64;
      Timestamp : Int_64;
      Addr_Recv : Net_Addr;
      addr_from : Net_Addr;
      Nonce : Uint_64;
      User_Agent: Uint_8; --  ??? We will hardcode this to 0 for now
      Start_Height : Int_32;
   end record;

   Ver : Version_Data :=
      (Version => 60002,
       Services => 1,
       Timestamp => Int_64 (Ada.Calendar.Conversions.To_Unix_Time (Ada.Calendar.Clock)),
       Addr_Recv => Mk_Addr,
       Addr_From => Mk_Addr,
       Nonce  =>  1,
       User_Agent => 0,
       Start_Height => 52144);
   
   P : Payload (1 .. Ver'Size / 8);
   for P'Address use Ver'Address;
       
begin
   Address.Addr := Addresses (Get_Host_By_Name (Host_Name), 1);
   Address.Port := 18333;
   Create_Socket (Socket);
   Connect_Socket (Socket, Address);
   Channel := Stream (Socket);
   
   Send_Msg (Version, P);
   while True loop
      Rec_Msg;
   end loop;

end Connect;
