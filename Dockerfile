ARG NODE_VERSION=12
FROM node:$NODE_VERSION as APP

WORKDIR /opt
RUN npx create-react-app visual-regression && \
    cd visual-regression

WORKDIR /opt/visual-regression

CMD [ "npm", "start" ]

