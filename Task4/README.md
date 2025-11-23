# Задание 4. Защита доступа к кластеру Kubernetes

### Что нужно сделать

1. Поднимите пустой Minikube.
2. Определите все роли и их полномочия при работе с Kubernetes. Заполните таблицу: укажите там роли, их полномочия и группы пользователей, которые им соответствуют.
3. Подготовьте скрипты для создания пользователей. Рекомендуем создать не менее двух пользователей.
4. Подготовьте скрипты, чтобы создать роли. Они должны соответствовать ролям из вашей таблицы.
5. Подготовьте скрипты, чтобы связать пользователей с ролями.

# Решение

## Роли доступа

| Роль  | Права роли | Группы пользователей |
| --- | --- | --- |
| Название роли, которое отвечает требованиям RBAC в Kubernets. | Укажите права, которые необходимо выдать этой роли. | Выделите группы пользователей в организации, которые нужно связать с этой ролью. |
| cluster-viewer      | `get`, `list`, `watch` для всех ресурсов (кроме Secrets)    | Администраторы группы приложений |
| cluster-admin       | Полные права (`*`) на все ресурсы  | DevOps-инженеры | 
| namespace-contributor   | `get`, `list`, `watch`, `create`, `update`, `delete` в пределах namespace  | Разработчики, Тестировщики   |
| ci-pipeline         | `create`, `get`, `list`, `delete` для Pods/Jobs в CI-неймспейсах | CI/CD системы  |
| pod-reader  | `get`, `list` для логов Pods и событий   | 2я линия тех.поддержки, дежурство в нерабочее время  |
| network-admin | Управление NetworkPolicies и Ingress (`create`, `patch`, `delete`) | Сетевые инженеры   |

## Create users

```bash
./01_create_user.sh admin1 app-admins
./01_create_user.sh devops1 devops
./01_create_user.sh developer1 developers
./01_create_user.sh tester1 qa
./01_create_user.sh svc-ci-account1 ci-systems
./01_create_user.sh support1 support-level2
./01_create_user.sh netadmin1 netops
```

## Create roles
```bash
kubectl apply -f ./02_roles.yml
```

## Create bindings
```bash
kubectl apply -f ./03_bindings.yml
```

## Проверка

Авторизоватся под одним из созданных юзеров:
```bash
export KUBECONFIG=./users/netadmin1-kubeconfig
kubectl auth can-i --list
```

Откатить проверку так:
```bash
unset KUBECONFIG
```