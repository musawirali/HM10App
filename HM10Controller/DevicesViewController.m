//
//  DevicesViewController.m
//  HM10Controller
//
//  Created by Musawir Shah on 2/14/14.
//  Copyright (c) 2014 Musawir Shah. All rights reserved.
//

#import "DevicesViewController.h"
#import "MainViewController.h"

@interface DevicesViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *discoveredPeripheral;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *conindicator;
@property (strong, nonatomic) NSMutableDictionary *devices;
@end

@implementation DevicesViewController
@synthesize centralManager = _centralManager;
@synthesize discoveredPeripheral = _discoveredPeripheral;
@synthesize devices = _devices;

- (NSMutableDictionary *)devices
{
    if (_devices == nil)
    {
        _devices = [NSMutableDictionary dictionaryWithCapacity:3];
    }
    return _devices;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // You should test all scenarios
    if (central.state != CBCentralManagerStatePoweredOn)
    {
        return;
    }
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        // Scan for devices
        [_centralManager scanForPeripheralsWithServices:nil options:nil];
        NSLog(@"Scanning started");
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSString * uuid = [[peripheral identifier] UUIDString];
    if (uuid)
    {
        [self.devices setObject:peripheral forKey:uuid];
    }
    
    [self.tableView reloadData];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected");
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService * service in [peripheral services])
    {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    for (CBCharacteristic * character in [service characteristics])
    {
        [peripheral discoverDescriptorsForCharacteristic:character];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    const char * bytes =[(NSData*)[[characteristic UUID] data] bytes];
    if (bytes && strlen(bytes) == 2 && bytes[0] == (char)255 && bytes[1] == (char)225)
    {
        [self.conindicator stopAnimating];
        MainViewController * mainVC = [[self.navigationController viewControllers] objectAtIndex:0];
        mainVC.centralManager = self.centralManager;
        mainVC.connectdPeri = peripheral;
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    int x = 0;
    unsigned char * bytes = [[characteristic value] bytes];
    NSString * str = [[NSString alloc] initWithData:[characteristic value] encoding:NSUTF8StringEncoding];
    x = 1;
    NSLog(@"%@\n", str);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error
{
    int x = 0;
}

// Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.devices allKeys] count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray * uuids = [[self.devices allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    CBPeripheral * peri = nil;
    if ([indexPath row] < [uuids count])
    {
        peri = [self.devices objectForKey:[uuids objectAtIndex:[indexPath row]]];
    }
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"devices_cell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"devices_cell"];
    }
    
    if (peri)
    {
        cell.textLabel.text = [peri name];
        cell.detailTextLabel.text = [uuids objectAtIndex:[indexPath row]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray * uuids = [[self.devices allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    CBPeripheral * peri = nil;
    if ([indexPath row] < [uuids count])
    {
        peri = [self.devices objectForKey:[uuids objectAtIndex:[indexPath row]]];
        if (peri)
        {
            [_centralManager connectPeripheral:peri options:nil];
            [self.conindicator startAnimating];
        }
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.conindicator stopAnimating];
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
