# Задание 5. Управление трафиком внутри кластера Kubertnetes

Нужно разграничить трафик между сервисами, которые развёрнуты в кластере Kubernetes:

- Вам необходимо добавить новый сервис. В терминах Kubernetes это под (pod). При этом нужно запретить другим подам с ним взаимодействовать.
- Необходимо изолировать трафик к новому сервису от других подов.
- Создайте сетевые политики.

# Решение

Для minikube дополнительно сделать:
```bash
minikube start --cni=calico
```

Запустить сервисы:
```bash
kubectl apply -f ./nginx-services.yml
```

Применить сетевые политики:
```bash
kubectl apply -f ./non-admin-api-allow.yaml
```

Проверка:
```bash
kubectl run test-$RANDOM --rm -i -t --image=alpine -- sh

##
wget -qO- http://front-end-app | grep h1 # запрос пройдет
wget -qO- http://admin-back-end-api-app | grep h1 # запрос не пройдет
```

Или:
```bash
kubectl exec admin-back-end-api -it -- sh

##
apt update
apt install wget
wget -qO- http://back-end-api-app | grep h1  # запрос не пройдет
wget -qO- http://front-end-app | grep h1 # запрос не пройдет
wget -qO- http://admin-back-end-api-app | grep h1 # запрос пройдет
wget -qO- http://admin-front-end-app | grep h1 # запрос пройдет
```
