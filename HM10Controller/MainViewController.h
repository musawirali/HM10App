//
//  MainViewController.h
//  HM10Controller
//
//  Created by Musawir Shah on 2/14/14.
//  Copyright (c) 2014 Musawir Shah. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface MainViewController : UIViewController<CBPeripheralDelegate, CBCentralManagerDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *connectdPeri;

@end
