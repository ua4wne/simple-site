FROM nginx:1.28.0

# удаляем дефолтную страницу
RUN rm -rf /usr/share/nginx/html/*

# загружаем свой контент
COPY src/ /usr/share/nginx/html/

EXPOSE 80