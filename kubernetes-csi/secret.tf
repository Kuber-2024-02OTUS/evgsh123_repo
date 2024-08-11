resource "kubernetes_secret" "csi-s3-secret" {
  metadata {
    name = "csi-s3-secret"
    namespace= "kube-system"
  }

  data = {
   accessKeyID: "${yandex_iam_service_account_static_access_key.s3.access_key}"
   secretAccessKey: "${yandex_iam_service_account_static_access_key.s3.secret_key}"
   endpoint: "https://storage.yandexcloud.net"
  }
}