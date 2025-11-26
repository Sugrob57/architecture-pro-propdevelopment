# Задание 7. Аудит и обеспечение соответствия политике безопасности контейнеров (PSP / PodSecurity / OPA Gatekee

В кластере происходят развёртывания подов, которые нарушают требования безопасной конфигурации. Ваша задача — выявить такие случаи и организовать аудит.
Что нужно сделать:
1. Создайте namespace audit-zone с уровнем PodSecurity restricted.
2. Разверните три манифеста с нарушениями в `insecure-manifests/`:
    - `01-privileged-pod.yaml` — включает `privileged: true`.
    - `02-hostpath-pod.yaml` — монтирует `hostPath`.
    - `03-root-user-pod.yaml` — запускается от root (UID 0).
3. Убедитесь, что манифесты НЕ проходят валидацию в audit-zone (если всё верно, admission controller их заблокирует).
4. Исправьте манифесты, чтобы они соответствовали политике, сохраните в `secure-manifests/`.
5. Настройте OPA Gatekeeper с набором правил:
    - Нельзя использовать `privileged: true`.
    - Только `runAsNonRoot: true`.
    - `readOnlyRootFilesystem`: true обязательно.
    - `hostPath` запрещён.

# Решение

## Настойка minikube
Запустить миникуб с маунтом:
```bash
# в примере папка ~/sprint5/Task6
minikube start \
  --mount-string="$HOME/sprint5/architecture-pro-propdevelopment/Task7:/var/lib/kubeadm" \
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

## Решение задания 

Установить Gatekeeper:
```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.16/deploy/gatekeeper.yaml
```

Создать namespace:
```bash
kubectl apply -f ./01-create-namespace.yaml
```

Развернуть insecure-manifests:
```bash
kubectl apply -f insecure-manifests/
```

Установить Constraint Templates:
```bash
kubectl apply -f ./gatekeeper/constraint-templates/
```

Установить Constraints:
```bash
kubectl apply -f ./gatekeeper/constraints/
```

Проверить insecure (попытки создать поды должны упасть)
```bash
bash ./verify/verify-admission.sh
```

Проверить secure (должны пройти успешно)
```bash
bash ./verify/validate-security.sh
```

## Очистка кластера

```bash
bash ./cleanup.sh
```