//
//  ViewController.m
//  KMJPZipLookUpSample
//
//  Created by Kosuke Matsuda on 2013/04/23.
//  Copyright (c) 2013年 matsuda. All rights reserved.
//

#import "ViewController.h"
#import "KMJPZipLookUpClient.h"
#import "KMJPZipLookUpResponse.h"
#import "KMJPZipLookUpAddressListViewController.h"

@interface ViewController () <UIPopoverControllerDelegate> {
    UIPopoverController *_popover;
    // ZipSearch
    KMJPZipLookUpResponse *_response;
}

@end

@implementation ViewController

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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)lookUp:(id)sender
{
    [self requestAPIWithZipcode:self.textField.text];
}

- (void)requestAPIWithZipcode:(NSString *)zipcode
{
    NSError *error = nil;
    if (![[KMJPZipLookUpClient sharedClient] validateZipcode:zipcode withError:&error]) {
        NSDictionary *userInfo = error.userInfo;
        NSString *message = userInfo[NSLocalizedDescriptionKey];
        [self showAlertNotFoundAddressListWithMessage:message];
        return;
    }

    __weak typeof(self) wself = self;
    [[KMJPZipLookUpClient sharedClient] lookUpWithZipcode:zipcode success:^(AFHTTPRequestOperation *operation, KMJPZipLookUpResponse *response){
        NSLog(@"success >>>>>>>> %@", response);
        _response = response;
        [wself didFinishCheckZipSearchAPI];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error){
        NSLog(@"failure >>>>>>>> %@", error);
        [wself didFailCheckZipSearchAPIWithError:error];
    }];
}

- (void)didFinishCheckZipSearchAPI
{
    NSArray *addresses = _response.addresses;
    if ([addresses count] > 0) {
        [self presentAddressListPopover];
    } else {
        [self showAlertNotFoundAddressListWithMessage:@"該当する住所が見つかりませんでした。"];
    }
}

- (void)didFailCheckZipSearchAPIWithError:(NSError *)error
{
    NSString *message = [error localizedDescription];
    [self showAlertNotFoundAddressListWithMessage:message];
}

#pragma mark - Private

- (void)didSelectAddress:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    KMJPZipLookUpAddress *address = [userInfo objectForKey:kKMJPZipLookUpAddressListResultsKey];
    self.label.text = [address fullAddress];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kKMJPZipLookUpAddressListDidSelectNotification object:nil];

    UIPopoverController *popover = [self addressListPopover];
    [popover dismissPopoverAnimated:YES];
    _popover = nil;
}

- (void)showAlertNotFoundAddressListWithMessage:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"郵便番号検索" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)presentAddressListPopover
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAddress:) name:kKMJPZipLookUpAddressListDidSelectNotification object:nil];

    UIPopoverController *popover = [self addressListPopover];
    [(KMJPZipLookUpAddressListViewController *)popover.contentViewController setResponse:_response];
    [popover setPopoverContentSize:CGSizeMake(400.f, 132.f)];
    [popover presentPopoverFromRect:self.textField.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
}

- (UIPopoverController *)addressListPopover
{
    if (_popover) {
        return _popover;
    }

    KMJPZipLookUpAddressListViewController *popoverContent = [[KMJPZipLookUpAddressListViewController alloc] initWithStyle:UITableViewStylePlain];
    _popover = [[UIPopoverController alloc] initWithContentViewController:popoverContent];
    _popover.delegate = self;
    return _popover;
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if ([popoverController isEqual:_popover]) {
        _popover = nil;
    }
}

@end
