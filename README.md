# KMJPZipLookUp

日本の郵便番号を元に住所を検索します。  
機能は郵便番号から住所を検索するだけです。  
通信用のAPIに[AFNetworking][AFN]を利用しています。

## セットアップ

* KMJPZipLookUpフォルダ以下のファイルをプロジェクトにコピー
* AFNetworkingの設定

## 利用方法

        [[KMJPZipLookUpClient sharedClient] lookUpWithZipcode:@"1000001" success:^(AFHTTPRequestOperation *operation, KMJPZipLookUpResponse *response){
            NSArray *addresses = response.addresses;
            NSLog(@"addresses >>>>>>>> %@", [addresses[0] fullAddress]); # => 東京都千代田区千代田
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            NSLog(@"error >>>>>>>> %@", error);
        }];

その他の使い方は、*KMJPZipLookUpSample*プロジェクトを参照してください。

## 郵便番号検索APIについて

APIは[郵便番号検索API][zip]を利用させてもらっています。  
利用についてはそちらのサイトの規約に従ってください。

[AFN]:https://github.com/AFNetworking/AFNetworking
[zip]:http://zip.cgis.biz
