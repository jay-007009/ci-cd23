terraform{
    backend "s3"{
        bucket="78965478lo" //s3 mathi copy karyu
        encrypt=true
        key="terraform.tfstate"
        region="us-east-1"
    }
}

provider "aws"{
    region="us-east-1"
}