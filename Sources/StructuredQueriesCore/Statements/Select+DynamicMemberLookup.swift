#if compiler(>=6.1)
  // NB: Using a parameter pack in the dynamic member results in 'EXC_BAD_ACCESS'.
  //     These overloads work around the problem.
  extension Select {
    public subscript<
      each C: QueryRepresentable,
      each J: Table,
      S: SelectStatement<(), From, ()>
    >(
      dynamicMember keyPath: KeyPath<From.Type, S>
    ) -> Select<(repeat each C), From, (repeat each J)>
    where Columns == (repeat each C), Joins == (repeat each J) {
      self + From.self[keyPath: keyPath]
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      each J: Table
    >(
      dynamicMember keyPath: KeyPath<From.Type, Select<C2, From, ()>>
    ) -> Select<(repeat each C1, C2), From, (repeat each J)>
    where Columns == (repeat each C1), Joins == (repeat each J) {
      self + From.self[keyPath: keyPath]
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      C3: QueryRepresentable,
      each J: Table
    >(
      dynamicMember keyPath: KeyPath<From.Type, Select<(C2, C3), From, ()>>
    ) -> Select<(repeat each C1, C2, C3), From, (repeat each J)>
    where Columns == (repeat each C1), Joins == (repeat each J) {
      self + From.self[keyPath: keyPath]
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      C3: QueryRepresentable,
      C4: QueryRepresentable,
      each J: Table
    >(
      dynamicMember keyPath: KeyPath<From.Type, Select<(C2, C3, C4), From, ()>>
    ) -> Select<(repeat each C1, C2, C3, C4), From, (repeat each J)>
    where Columns == (repeat each C1), Joins == (repeat each J) {
      self + From.self[keyPath: keyPath]
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      C3: QueryRepresentable,
      C4: QueryRepresentable,
      C5: QueryRepresentable,
      each J: Table
    >(
      dynamicMember keyPath: KeyPath<From.Type, Select<(C2, C3, C4, C5), From, ()>>
    ) -> Select<(repeat each C1, C2, C3, C4, C5), From, (repeat each J)>
    where Columns == (repeat each C1), Joins == (repeat each J) {
      self + From.self[keyPath: keyPath]
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      each J1: Table,
      J2: Table
    >(
      dynamicMember keyPath: KeyPath<From.Type, Select<C2, From, J2>>
    ) -> Select<(repeat each C1, C2), From, (repeat each J1, J2)>
    where Columns == (repeat each C1), Joins == (repeat each J1) {
      self + From.self[keyPath: keyPath]
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      C3: QueryRepresentable,
      each J1: Table,
      J2: Table
    >(
      dynamicMember keyPath: KeyPath<From.Type, Select<(C2, C3), From, J2>>
    ) -> Select<(repeat each C1, C2, C3), From, (repeat each J1, J2)>
    where Columns == (repeat each C1), Joins == (repeat each J1) {
      self + From.self[keyPath: keyPath]
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      C3: QueryRepresentable,
      C4: QueryRepresentable,
      each J1: Table,
      J2: Table
    >(
      dynamicMember keyPath: KeyPath<From.Type, Select<(C2, C3, C4), From, J2>>
    ) -> Select<(repeat each C1, C2, C3, C4), From, (repeat each J1, J2)>
    where Columns == (repeat each C1), Joins == (repeat each J1) {
      self + From.self[keyPath: keyPath]
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      C3: QueryRepresentable,
      C4: QueryRepresentable,
      C5: QueryRepresentable,
      each J1: Table,
      J2: Table
    >(
      dynamicMember keyPath: KeyPath<From.Type, Select<(C2, C3, C4, C5), From, J2>>
    ) -> Select<(repeat each C1, C2, C3, C4, C5), From, (repeat each J1, J2)>
    where Columns == (repeat each C1), Joins == (repeat each J1) {
      self + From.self[keyPath: keyPath]
    }

    public subscript<
      each C: QueryRepresentable,
      each J1: Table,
      J2: Table,
      J3: Table
    >(
      dynamicMember keyPath: KeyPath<From.Type, Select<(), From, (J2, J3)>>
    ) -> Select<(repeat each C), From, (repeat each J1, J2, J3)>
    where Columns == (repeat each C), Joins == (repeat each J1) {
      self + From.self[keyPath: keyPath]
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      each J1: Table,
      J2: Table,
      J3: Table
    >(
      dynamicMember keyPath: KeyPath<From.Type, Select<C2, From, (J2, J3)>>
    ) -> Select<(repeat each C1, C2), From, (repeat each J1, J2, J3)>
    where Columns == (repeat each C1), Joins == (repeat each J1) {
      self + From.self[keyPath: keyPath]
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      C3: QueryRepresentable,
      each J1: Table,
      J2: Table,
      J3: Table
    >(
      dynamicMember keyPath: KeyPath<From.Type, Select<(C2, C3), From, (J2, J3)>>
    ) -> Select<(repeat each C1, C2, C3), From, (repeat each J1, J2, J3)>
    where Columns == (repeat each C1), Joins == (repeat each J1) {
      self + From.self[keyPath: keyPath]
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      C3: QueryRepresentable,
      C4: QueryRepresentable,
      each J1: Table,
      J2: Table,
      J3: Table
    >(
      dynamicMember keyPath: KeyPath<From.Type, Select<(C2, C3, C4), From, (J2, J3)>>
    ) -> Select<(repeat each C1, C2, C3, C4), From, (repeat each J1, J2, J3)>
    where Columns == (repeat each C1), Joins == (repeat each J1) {
      self + From.self[keyPath: keyPath]
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      C3: QueryRepresentable,
      C4: QueryRepresentable,
      C5: QueryRepresentable,
      each J1: Table,
      J2: Table,
      J3: Table
    >(
      dynamicMember keyPath: KeyPath<From.Type, Select<(C2, C3, C4, C5), From, (J2, J3)>>
    ) -> Select<(repeat each C1, C2, C3, C4, C5), From, (repeat each J1, J2, J3)>
    where Columns == (repeat each C1), Joins == (repeat each J1) {
      self + From.self[keyPath: keyPath]
    }
  }

  extension Select where From: TableDraft {
    public subscript<
      each C: QueryRepresentable,
      each J: Table,
      S: SelectStatement<(), From.PrimaryTable, ()>
    >(
      dynamicMember keyPath: KeyPath<From.PrimaryTable.Type, S>
    ) -> Select<(repeat each C), From, (repeat each J)>
    where Columns == (repeat each C), Joins == (repeat each J) {
      self
        + unsafeBitCast(
          From.PrimaryTable.self[keyPath: keyPath].asSelect(),
          to: Select<(), From, ()>.self
        )
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      each J: Table
    >(
      dynamicMember keyPath: KeyPath<From.PrimaryTable.Type, Select<C2, From.PrimaryTable, ()>>
    ) -> Select<(repeat each C1, C2), From, (repeat each J)>
    where Columns == (repeat each C1), Joins == (repeat each J) {
      self
        + unsafeBitCast(
          From.PrimaryTable.self[keyPath: keyPath],
          to: Select<C2, From, ()>.self
        )
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      C3: QueryRepresentable,
      each J: Table
    >(
      dynamicMember keyPath: KeyPath<
        From.PrimaryTable.Type, Select<(C2, C3), From.PrimaryTable, ()>
      >
    ) -> Select<(repeat each C1, C2, C3), From, (repeat each J)>
    where Columns == (repeat each C1), Joins == (repeat each J) {
      self
        + unsafeBitCast(
          From.PrimaryTable.self[keyPath: keyPath],
          to: Select<(C2, C3), From, ()>.self
        )
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      C3: QueryRepresentable,
      C4: QueryRepresentable,
      each J: Table
    >(
      dynamicMember keyPath: KeyPath<
        From.PrimaryTable.Type, Select<(C2, C3, C4), From.PrimaryTable, ()>
      >
    ) -> Select<(repeat each C1, C2, C3, C4), From, (repeat each J)>
    where Columns == (repeat each C1), Joins == (repeat each J) {
      self
        + unsafeBitCast(
          From.PrimaryTable.self[keyPath: keyPath],
          to: Select<(C2, C3, C4), From, ()>.self
        )
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      C3: QueryRepresentable,
      C4: QueryRepresentable,
      C5: QueryRepresentable,
      each J: Table
    >(
      dynamicMember keyPath: KeyPath<
        From.PrimaryTable.Type, Select<(C2, C3, C4, C5), From.PrimaryTable, ()>
      >
    ) -> Select<(repeat each C1, C2, C3, C4, C5), From, (repeat each J)>
    where Columns == (repeat each C1), Joins == (repeat each J) {
      self
        + unsafeBitCast(
          From.PrimaryTable.self[keyPath: keyPath],
          to: Select<(C2, C3, C4, C5), From, ()>.self
        )
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      each J1: Table,
      J2: Table
    >(
      dynamicMember keyPath: KeyPath<From.PrimaryTable.Type, Select<C2, From.PrimaryTable, J2>>
    ) -> Select<(repeat each C1, C2), From, (repeat each J1, J2)>
    where Columns == (repeat each C1), Joins == (repeat each J1) {
      self
        + unsafeBitCast(
          From.PrimaryTable.self[keyPath: keyPath],
          to: Select<C2, From, J2>.self
        )
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      C3: QueryRepresentable,
      each J1: Table,
      J2: Table
    >(
      dynamicMember keyPath: KeyPath<
        From.PrimaryTable.Type, Select<(C2, C3), From.PrimaryTable, J2>
      >
    ) -> Select<(repeat each C1, C2, C3), From, (repeat each J1, J2)>
    where Columns == (repeat each C1), Joins == (repeat each J1) {
      self
        + unsafeBitCast(
          From.PrimaryTable.self[keyPath: keyPath],
          to: Select<(C2, C3), From, J2>.self
        )
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      C3: QueryRepresentable,
      C4: QueryRepresentable,
      each J1: Table,
      J2: Table
    >(
      dynamicMember keyPath: KeyPath<
        From.PrimaryTable.Type, Select<(C2, C3, C4), From.PrimaryTable, J2>
      >
    ) -> Select<(repeat each C1, C2, C3, C4), From, (repeat each J1, J2)>
    where Columns == (repeat each C1), Joins == (repeat each J1) {
      self
        + unsafeBitCast(
          From.PrimaryTable.self[keyPath: keyPath],
          to: Select<(C2, C3, C4), From, J2>.self
        )
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      C3: QueryRepresentable,
      C4: QueryRepresentable,
      C5: QueryRepresentable,
      each J1: Table,
      J2: Table
    >(
      dynamicMember keyPath: KeyPath<
        From.PrimaryTable.Type, Select<(C2, C3, C4, C5), From.PrimaryTable, J2>
      >
    ) -> Select<(repeat each C1, C2, C3, C4, C5), From, (repeat each J1, J2)>
    where Columns == (repeat each C1), Joins == (repeat each J1) {
      self
        + unsafeBitCast(
          From.PrimaryTable.self[keyPath: keyPath],
          to: Select<(C2, C3, C4, C5), From, J2>.self
        )
    }

    public subscript<
      each C: QueryRepresentable,
      each J1: Table,
      J2: Table,
      J3: Table
    >(
      dynamicMember keyPath: KeyPath<
        From.PrimaryTable.Type, Select<(), From.PrimaryTable, (J2, J3)>
      >
    ) -> Select<(repeat each C), From, (repeat each J1, J2, J3)>
    where Columns == (repeat each C), Joins == (repeat each J1) {
      self
        + unsafeBitCast(
          From.PrimaryTable.self[keyPath: keyPath],
          to: Select<(), From, (J2, J3)>.self
        )
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      each J1: Table,
      J2: Table,
      J3: Table
    >(
      dynamicMember keyPath: KeyPath<
        From.PrimaryTable.Type, Select<C2, From.PrimaryTable, (J2, J3)>
      >
    ) -> Select<(repeat each C1, C2), From, (repeat each J1, J2, J3)>
    where Columns == (repeat each C1), Joins == (repeat each J1) {
      self
        + unsafeBitCast(
          From.PrimaryTable.self[keyPath: keyPath],
          to: Select<C2, From, (J2, J3)>.self
        )
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      C3: QueryRepresentable,
      each J1: Table,
      J2: Table,
      J3: Table
    >(
      dynamicMember keyPath: KeyPath<
        From.PrimaryTable.Type, Select<(C2, C3), From.PrimaryTable, (J2, J3)>
      >
    ) -> Select<(repeat each C1, C2, C3), From, (repeat each J1, J2, J3)>
    where Columns == (repeat each C1), Joins == (repeat each J1) {
      self
        + unsafeBitCast(
          From.PrimaryTable.self[keyPath: keyPath],
          to: Select<(C2, C3), From, (J2, J3)>.self
        )
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      C3: QueryRepresentable,
      C4: QueryRepresentable,
      each J1: Table,
      J2: Table,
      J3: Table
    >(
      dynamicMember keyPath: KeyPath<
        From.PrimaryTable.Type, Select<(C2, C3, C4), From.PrimaryTable, (J2, J3)>
      >
    ) -> Select<(repeat each C1, C2, C3, C4), From, (repeat each J1, J2, J3)>
    where Columns == (repeat each C1), Joins == (repeat each J1) {
      self
        + unsafeBitCast(
          From.PrimaryTable.self[keyPath: keyPath],
          to: Select<(C2, C3, C4), From, (J2, J3)>.self
        )
    }

    public subscript<
      each C1: QueryRepresentable,
      C2: QueryRepresentable,
      C3: QueryRepresentable,
      C4: QueryRepresentable,
      C5: QueryRepresentable,
      each J1: Table,
      J2: Table,
      J3: Table
    >(
      dynamicMember keyPath: KeyPath<
        From.PrimaryTable.Type, Select<(C2, C3, C4, C5), From.PrimaryTable, (J2, J3)>
      >
    ) -> Select<(repeat each C1, C2, C3, C4, C5), From, (repeat each J1, J2, J3)>
    where Columns == (repeat each C1), Joins == (repeat each J1) {
      self
        + unsafeBitCast(
          From.PrimaryTable.self[keyPath: keyPath],
          to: Select<(C2, C3, C4, C5), From, (J2, J3)>.self
        )
    }
  }
#endif
