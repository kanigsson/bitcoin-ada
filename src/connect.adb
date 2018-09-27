with GNAT.Sockets; use GNAT.Sockets;
with Types; use Types;
with Ada.Text_IO;
with Ada.Calendar;
with Ada.Calendar.Conversions;
with Ada.Streams;

procedure Connect is
   Address  : Sock_Addr_Type;
   --Server   : Socket_Type;
   Socket   : Socket_Type;
   Channel  : Stream_Access;

   type NUint_64 is new Uint_64;
     
   procedure Write_NUint_64
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : in  NUint_64);
   for NUint_64'Write use Write_NUint_64;

   procedure Write_NUint_64
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : in  NUint_64) is
   
      Ar : array (1 .. 8) of Uint_8;
      for Ar'Address use Item'Address;
   begin
      for I in reverse Ar'range loop
         Uint_8'Write (Stream, Ar (I));
      end loop;
   end Write_NUint_64;

   type NInt_64 is new Int_64;
   
   procedure Write_NInt_64
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : in  NInt_64);
   for NInt_64'Write use Write_NInt_64;

   procedure Write_NInt_64
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : in  NInt_64) is
   
      Ar : array (1 .. 2) of Uint_32;
      for Ar'Address use Item'Address;
   begin
      Uint_32'Write (Stream, Ar (1));
      Uint_32'Write (Stream, Ar (2));
   end Write_NInt_64;
   
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

   subtype Ipaddr is Inet_Addr_Bytes (1 .. 16);

   function Convert_Ipaddr (Addr : Inet_Addr_Type) return Ipaddr;

   --------------------
   -- Convert_Ipaddr --
   --------------------

   function Convert_Ipaddr (Addr : Inet_Addr_Type) return Ipaddr is
   begin
      case Addr.Family is
         when Family_Inet6 => return Addr.Sin_V6;
         when Family_Inet =>
            return Result : Ipaddr do
               Result (1 .. 10) := (1 .. 10 => 0);
               Result (11 .. 12) := (255, 255);
               Result (13 .. 16) := Addr.Sin_V4;
            end return;
      end case;
   end Convert_Ipaddr;

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

   type Net_Addr is record
      Services : NUint_64;
      IPv6 : Ipaddr;
      Port : Port_Type;
   end record;

   function Mk_Addr  (Addr : Sock_Addr_Type) return Net_Addr is
      T : Net_Addr;
   begin
      T :=
        (Services => 1,
         Ipv6     => Convert_Ipaddr (Addr.Addr),
         Port     => Port_Type (Addr.Port));
      return T;
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
      Services : NUint_64;
      Timestamp : NInt_64;
      Addr_Recv : Net_Addr;
      addr_from : Net_Addr;
      Nonce : NUint_64;
      User_Agent: Uint_8; --  ??? We will hardcode this to 0 for now
      Start_Height : Int_32;
   end record;

   function Build_Version_Payload
     (From, To : Sock_Addr_Type) return Payload;

   ---------------------------
   -- Build_Version_Payload --
   ---------------------------

   function Build_Version_Payload
     (From, To : Sock_Addr_Type) return Payload
   is
      Ver : Version_Data :=
        (Version => 60002,
         Services => 1,
         Timestamp =>
           Nint_64 (Ada.Calendar.Conversions.To_Unix_Time (Ada.Calendar.Clock)),
         Addr_Recv => Mk_Addr (To),
         Addr_From => Mk_Addr (From),
         Nonce  =>  1,
         User_Agent => 0,
         Start_Height => 52144);
      P : Payload (1 .. Ver'Size / 8);
      for P'Address use Ver'Address;
   begin
      return P;
   end Build_Version_Payload;

begin
   Address.Addr := Addresses (Get_Host_By_Name (Host_Name), 1);
   Address.Port := 18333;
   Ada.Text_IO.Put_Line ("creating socket...");
   Create_Socket (Socket);
   Ada.Text_IO.Put_Line ("connecting to "  & Image (Address.Addr) & " ...");
   Connect_Socket (Socket, Address);
   Channel := Stream (Socket);

   Ada.Text_IO.Put_Line ("sending version msg ...");
   Send_Msg (Version,
             Build_Version_Payload
               (Get_Socket_Name (Socket),
                Address));
   while True loop
      Ada.Text_IO.Put_Line ("waiting for msg ...");
      Rec_Msg;
   end loop;

end Connect;
