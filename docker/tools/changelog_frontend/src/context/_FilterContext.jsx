import React, { useState } from "react";

const AuthorFilterContext = React.createContext();
const ComponentFilterContext = React.createContext();

const AuthorFilterProvider = props => {
  const [state, setState] = useState({});
  return (
    <AuthorFilterContext.Provider value={[state, setState]}>
      {props.children}
    </AuthorFilterContext.Provider>
  );
};

const ComponentFilterProvider = props => {
  const [state, setState] = useState({});
  return (
    <ComponentFilterContext.Provider value={[state, setState]}>
      {props.children}
    </ComponentFilterContext.Provider>
  );
};

export {
  AuthorFilterContext,
  AuthorFilterProvider,
  ComponentFilterContext,
  ComponentFilterProvider
};
