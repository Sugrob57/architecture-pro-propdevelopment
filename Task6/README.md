# Задание 6. Аудит активности пользователей и обнаружение инцидентов

Необходимо настроить аудит активности пользователей, чтобы своевременно обнаруживать аномалии, попытки несанкционированного доступа и другие угрозы.

# Решение

## Настойка minikube
Запустить миникуб с маунтом:
```bash
# в примере папка ~/sprint5/Task6
minikube start \
  --mount-string="$HOME/sprint5/architecture-pro-propdevelopment/Task6:/var/lib/kubeadm" \
  --mount
```

войти в minikube container:
```bash
minikube ssh
```

```bash
# проверить что локальный файл политики видно
sudo cat /var/lib/kubeadm/audit-policy.yaml

# поставить nano (либо использовать vim)
sudo apt update
sudo apt install nano
sudo nano /etc/kubernetes/manifests/kube-apiserver.yaml
```

и внести изменения:
```bash
# - command (добавить строки)
    - --audit-policy-file=/var/lib/kubeadm/audit-policy.yaml
    - --audit-log-path=/var/lib/kubeadm/audit.log
    - --audit-log-maxage=30
    - --audit-log-maxbackup=10
    - --audit-log-maxsize=100

# volumeMounts (добавить строки)
    - mountPath: /var/lib/kubeadm
      name: audit-dir
      readonly: false

# volumes (добавить строки)
    - hostPath:
        path: /var/lib/kubeadm
        type: DirectoryOrCreate
      name: audit-dir
```

Подождать пока "kube-apiserver" напишет что перезапустился и находится в статусе Running:
```bash
sudo crictl --runtime-endpoint unix:///var/run/cri-dockerd.sock ps -a
```

Поисследовать проблемы можно так:
```bash
# внутри "minikube ssh"
sudo crictl --runtime-endpoint unix:///var/run/cri-dockerd.sock ps -a | grep apiserver
sudo crictl --runtime-endpoint unix:///var/run/cri-dockerd.sock logs 8f15291c6c981 # контейнеры бысто пересоздаются, можно не успеть забрать логи. Если так - получить новое имя и повторить
```

## Имитация инцидента

Строка `kubectl delete -f /etc/kubernetes/audit-policy.yaml --as=admin` закомментирована, т.к. неприменима для minikube (по причине ограничений, описанных выше).

Запустить:
```bash
./simulate-incident.sh 
```

## Разбор инцидента

Анализ инцидента: [analysis.md](/analysis.md)

Скрипты для парсинга событий:
- Вариант 1 (медленно но верно): [show_events2.sh](/show_events2.sh) 
- Вариант 2 (быстро, но падает на каком-то событии): [show_filtered_audit_events.sh](/show_filtered_audit_events.sh) 






