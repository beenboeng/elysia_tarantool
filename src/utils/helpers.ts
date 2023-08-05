
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
var msgpack_node = require('msgpack-nodejs');
const uuid = require('uuid');
dayjs.extend(utc);

//Handle Unpack Message Extension
export function handleConvertSpecailTypeData(buffer: Buffer, type: number) {
    switch (type) {
  
        // this case is to convert decimal type 
        case 1:
         
              // Extract the scale, BCD digits and sign.
              const scale = buffer[0];
              const bcdDigits = buffer.slice(1, -1);
              const lastDigitAndSign = buffer[buffer.length - 1];
  
              // Calculate the number by processing the BCD digits.
              let number = 0;
              for (let i = 0; i < bcdDigits.length; i++) {
                const byte = bcdDigits[i];
                const digit1 = byte >> 4;
                const digit2 = byte & 0b1111;
  
                number = number * 100 + digit1 * 10 + digit2;
              }
  
              // Process the last digit.
              const lastDigit = lastDigitAndSign >> 4;
              number = number * 10 + lastDigit;
  
              // Adjust by the scale.
              number = number / (10 ** scale);
  
              // Process the sign.
              const signNibble = lastDigitAndSign & 0b1111;
              if (signNibble === 0x0b || signNibble === 0x0d) {
                number = -number;
              }
  
              return number;
  
        // this case is to convert uuid  type
        case 2:
            var hexArray = [];
            for (var i = 0; i < buffer.length; i++) {
                var hexValue = buffer[i].toString(16).padStart(2, '0');
                hexArray.push(hexValue);
            }
            var uuidString = hexArray.join('');
  
            // Insert dashes at appropriate positions to form a UUID string
            uuidString = uuidString.slice(0, 8) + '-' + uuidString.slice(8, 12) + '-' + uuidString.slice(12, 16) + '-' + uuidString.slice(16, 20) + '-' + uuidString.slice(20);
  
            return uuidString;
   
        //
  
        // this case is to convert datetime type 
        case 4:
          const seconds = buffer.readBigInt64LE(0);
          const nanoseconds = buffer.length === 8 ? 0 : buffer.readUInt32LE(8);
          const date = new Date(Number(seconds) * 1000 + Number(nanoseconds) / 1000000);
  
          return date;
                  //
        default:
            break;
    }
  }


//Types for Pack MessagePack
export class UuidType {
  type: number;
  data: any;
  constructor(uuid: any) {
    this.type = 2;
    this.data = uuid;
  }
}

export class DateTimeType {
  type: number;
  data: any;
  constructor(datetime: any) {
    this.type = 4;
    this.data = datetime;
  }
}

export class DecimalType {
  type: number;
  data: any;
  constructor(decimal: any) {
    this.type = 1;
    this.data = decimal;
  }
}

msgpack_node.registerExtension({
  type: 2,
  objConstructor: UuidType,
  encode: function (object: any) {
    const metadataBuffer = Buffer.alloc(16); // 19 bytes for type (1 byte) + buffer length (1 byte) + MP_EXT (1 byte) + UUID (16 bytes)
    const uuidBuffer = Buffer.from(object.data.replace(/-/g, ''), 'hex'); // Convert UUID string to Buffer
    uuidBuffer.copy(metadataBuffer, 0); // Copy the UUID Buffer to the metadata buffer starting from index 3  
    return metadataBuffer;
  }
});

msgpack_node.registerExtension({
  type: 4,
  objConstructor: DateTimeType,
  encode: function (date_str: any) {
    const date = dayjs.utc(date_str.data);
  const seconds = date.unix();
  const nanoseconds = date.millisecond() * 1000000;
  const tzoffset = 0;
  const tzindex = 0;

  const buffer = Buffer.alloc(16);
  buffer.writeBigInt64LE(BigInt(seconds), 0); // Write seconds as little-endian i64 starting from index 0
  buffer.writeUInt32LE(nanoseconds, 8); // Write nanoseconds as little-endian u32 starting from index 8
  buffer.writeInt16LE(tzoffset, 12); // Write time zone offset as little-endian i16 starting from index 12
  buffer.writeUInt16LE(tzindex, 14); // Write time zone index as little-endian u16 starting from index 14
  return buffer;
  }
});


msgpack_node.registerExtension({
  type: 1,
  objConstructor: DecimalType,
  encode: function (object: any) {
    const decimal = object.data;
    const scale = Math.abs(decimal.toString().length - decimal.toString().indexOf('.') - 1);

    // Determine the sign of the decimal
    const sign = decimal < 0 ? 0x0d : 0x0c;

    // Convert the decimal to a string representation without the minus sign
    const absDecimalStr = Math.abs(decimal).toFixed(scale).replace('.', '');

    // Split the absolute decimal string into individual digits
    const digits = absDecimalStr.split('').map((digit) => parseInt(digit, 10));

    // Check if the number of digits is odd
    if (digits.length % 2 !== 0) {
      digits.unshift(0);
    }

    const numBytes = Math.ceil((digits.length + 1) / 2);
    const bcd = Buffer.alloc(numBytes);
    console.log("numBytes:",numBytes);
    let index = 0;
    for (let i = 0; i < digits.length; i += 2) {
      const first = digits[i] << 4;
      let second = 0;
      if (index != numBytes-1) {
        second = digits[i+1] & 0x0f;
      }else{//last index
        second |= sign;
      }
      
      const byte = first | second;
      bcd[index] = byte;
      index++;
    }

    // Combine the scale and the packed BCD bytes into a single buffer
    const packedBuffer = Buffer.alloc(numBytes + 1);
    packedBuffer.writeUInt8(scale+1, 0);
    bcd.copy(packedBuffer, 1);

    // Add the sign nibble at the correct position
    if (digits.length % 2 === 0) {
      packedBuffer[packedBuffer.length - 1] |= sign;
    } else {
      packedBuffer[packedBuffer.length - 1] |= sign << 4;
    }

    return packedBuffer;
  }
});