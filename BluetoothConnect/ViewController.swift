//
//  ViewController.swift
//  BluetoothConnect
//
//  Created by Rafael Goncalves on 06/11/17.
//  Copyright © 2017 Rafael Goncalves. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    var manager:CBCentralManager!
    var peripherals = Array<CBPeripheral>()
    var peri: CBPeripheral!
    var bytes: NSData!
    var characteristic: CBCharacteristic!
    fileprivate let data = NSMutableData()

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager = CBCentralManager(delegate: self, queue: nil)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        manager?.stopScan()
    }
    
    func connectBluetooth(peripheral: CBPeripheral){
        manager?.connect(peripheral, options: nil)
    }
}

extension ViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectPeripheral = self.peripherals[indexPath.row]
        //    self.peri = selectPeripheral
        connectBluetooth(peripheral: selectPeripheral)
        
        self.performSegue(withIdentifier: "goConnect", sender: selectPeripheral)
    }
}

extension ViewController: UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        let peripheral = peripherals[indexPath.row]
        cell.textLabel?.text = peripheral.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
}







extension ViewController: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("Bluetooth not available.")
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if peripheral.name != nil {
            peripherals.append(peripheral)
        }
        DispatchQueue.main.async() {
            
            self.tableView.reloadData()
        }
    }
    
    /** If the connection fails for whatever reason, we need to deal with it.
     */
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral). (\(error!.localizedDescription))")
        
      //  cleanup()
    }
    /** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
     */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Peripheral Connected")
        
        // Stop scanning
        manager?.stopScan()
        print("Scanning stopped")
        
        // Clear the data that we may already have
        data.length = 0
        
        peri = peripheral
        
        // Make sure we get the discovery callbacks
        peripheral.delegate = self
        
        // Search only for services that match our UUID
        peripheral.discoverServices(nil)
    }
   
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager)
    {
        print("state: \(peripheral.state)")
    }
}

extension ViewController: CBPeripheralDelegate{
    /** The Transfer Service was discovered
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("Error discovering services: \(error!.localizedDescription)")
          //  cleanup()
            return
        }
        
        guard peripheral.services != nil else {
            return
        }

        if let services = peripheral.services {
            for service in services {
                // 1
               // if (service.uuid == CBUUID(string: Device.NOVUS_SERVICE_UUID)) {
                    // 2
                    peripheral.discoverCharacteristics(nil, for: service)
                    print("SERIVCE UUID   \(service.uuid)")
                //}
            }
        }
        
     
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if error != nil {
            print("DEU RUIM NO WRITE VALUE FOR CHARACTERISTIC    = \(String(describing: error)) ")
            return
        }
        
        print("ENVIEI O PASSWORD\(characteristic)")
        peripheral.setNotifyValue(true, for: characteristic)
        print("INFORMACOES DO PERIPHERAL \(peripheral)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        if error != nil {
            print("DEU RUIM NO WRITE VALUE FOR DESCRIPTOR    = \(String(describing: error)) ")
            return
        }
        
        print("ENVIEI O PASSWORD E ESSE É O DESCRIPTOR \(descriptor)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(String(describing: error?.localizedDescription))")
            return
        }
        
        print("ENTREI NO DID UPDATE VALUE FOR CHARACTERISTIC = \(String(describing: peripheral)) E NOTIFY = \(String(describing: characteristic.value))")
        
    }
    
    /** The Transfer characteristic was discovered.
     *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
     */
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("ERROR DISCOVERING CHARACTERISTICS: \(String(describing: error?.localizedDescription))")
            return
        }
        
        
       // SERVICE ID     0783B03E-8535-B5A0-7140-A304D2495CB7
       // CHARACTERISTIC UID    0783B03E-8535-B5A0-7140-A304D2495CBA
        
        
        if let characteristics = service.characteristics {
            // 1
            //var enableValue:UInt8 = 1
           // let enableBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt8>.size)
            
            //array bytes ns data
           self.bytes = NSData(bytes: [0x5A, 0xB1, 0xFA, 0xBB, 0xC0, 0x3D, 0xFE, 0x34,0x45,0xCD,0x00,0x54,0x25,0x62,0x36,0x22] as [UInt8], length: 16)
           print("BYTES \(bytes)")
            let base64String = bytes.base64EncodedString(options: [])
            print("SENHA BASE 64 \(base64String)")
           // let newData = base64String.data(using: String.Encoding.utf8)
            //print(newData)
            
            let bytes2:[UInt8] = [0x5A, 0xB1, 0xFA, 0xBB, 0xC0, 0x3D, 0xFE, 0x34,0x45,0xCD,0x00,0x54,0x25,0x62,0x36,0x22]
            let data = Data(fromArray: bytes2)
            print("DATA \(data.hex())")
            
            
            let bytes3 = data.toArray(type: UInt8.self)
            print(bytes3)
            print("SENHA BYTE 3  \(bytes3)")
            
//            let bytes: [UInt8] = [107, 200, 119, 211, 247, 171, 132, 179, 181, 133, 54, 146, 206, 234, 69, 197]
//            let base64String = bytes.withUnsafeBufferPointer { buffer -> String in
//                let data = NSData(bytes: buffer.baseAddress, length: buffer.count)
//                return data.base64EncodedStringWithOptions([])
//            }
//            print(base64String)
//
            
            // 2
            for characteristic in characteristics {
                
                
                if characteristic.uuid == CBUUID(string: "0783B03E-8535-B5A0-7140-A304D2495CB8"){
                    peripheral.setNotifyValue(true, for: characteristic)
                    
                
                }
                    
                
                if characteristic.uuid == CBUUID(string: "0783B03E-8535-B5A0-7140-A304D2495CBA"){
                   // print("PRINT PASSWORD \(data.hex())")
                    
                    self.characteristic = characteristic
                  
                   // self.peri.writeValue(data, for: "") a
                 //   peri
                   peripheral.writeValue(bytes as Data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                    
                }
                
                if characteristic.uuid == CBUUID(string: Device.NOVUS_CHARACTERISTIC_UUID1) {
                    //peri.readValue(for: characteristic)
                    //peri.
                    
                //    peri?.setNotifyValue(true, for: characteristic)
                    
                }
                if characteristic.uuid == CBUUID(string: Device.NOVUS_CHARACTERISTIC_UUID2) {
                    //peri.readValue(for: characteristic)
                    //peri.
                    
                    //peri?.setNotifyValue(true, for: characteristic)
                    
                }
                
                if characteristic.uuid == CBUUID(string: Device.NOVUS_CHARACTERISTIC_UUID3) {
                    // 3a
                    // novus characteristic 1
                   // peri?.writeValue((bytes as NSData) as Data, for: characteristic, type: .withResponse)
             //      peri?.writeValue(newData!, for: characteristic, type: .withResponse)
                    if let newData = base64String.data(using: String.Encoding.utf8){
                        print(newData.hex())
                     //   peri?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                      //  peri.readValue(for: characteristic)
                    }
                }
            }
        }
        
    }
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        print(peripheral)
    }
    
        
    
    
    func displayTemperature(data:NSData) {
        // We'll get four bytes of data back, so we divide the byte count by two
        // because we're creating an array that holds two 16-bit (two-byte) values
        let dataLength = data.length / MemoryLayout<UInt16>.size
        
        // 1
        // create an array to contain the 16-bit values
        var dataArray = [UInt16](repeating: 0, count:dataLength)
        
        // 2
        // extract the data from the dataBytes object
        data.getBytes(&dataArray, length: dataLength * MemoryLayout<UInt16>.size)
        
     
    }
    
    /** The peripheral letting us know whether our subscribe/unsubscribe happened or not
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Error changing notification state: \(String(describing: error?.localizedDescription))")
        
        
        // Notification has started
        if (characteristic.isNotifying) {
            print("Notification began on \(characteristic)")
            peripheral.writeValue(self.bytes as! Data, for: self.characteristic, type: .withResponse)
            
        } else { // Notification has stopped
            print("Notification stopped on (\(characteristic))  Disconnecting")
            manager?.cancelPeripheralConnection(peripheral)
        }
    }
}



struct Device {
    //...
    
    static let NOVUS_SERVICE_UUID = "0783B03E-8535-B5A0-7140-A304D2495CB7"//service
    static let NOVUS_CHARACTERISTIC_UUID1 = "0783B03E-8535-B5A0-7140-A304D2495CB8"//ReadData, Notify
    static let NOVUS_CHARACTERISTIC_UUID2 = "0783B03E-8535-B5A0-7140-A304D2495CB9"//FlowControl
    static let NOVUS_CHARACTERISTIC_UUID3 = "0783B03E-8535-B5A0-7140-A304D2495CBA"//WriteData
    
    
}

extension Data {
    
    init<T>(fromArray values: [T]) {
        var values = values
        self.init(buffer: UnsafeBufferPointer(start: &values, count: values.count))
    }
    
    func toArray<T>(type: T.Type) -> [T] {
        return self.withUnsafeBytes {
            [T](UnsafeBufferPointer(start: $0, count: self.count/MemoryLayout<T>.stride))
        }
    }
    
}
extension Data {
    func hex(separator:String = "") -> String {
        return (self.map { String(format: "%02X", $0) }).joined(separator: separator)
    }
}

